/* Runtime-loaded SQLite C API.
   Each backend library (Turso's sqlite3-compatible lib, stock libsqlite3) is
   dlopen'ed with RTLD_LOCAL and called through its own function table, so
   several backends can coexist in one process (differential testing). */

#include <dlfcn.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

#define SQLITE_OK 0
#define SQLITE_ROW 100
#define SQLITE_DONE 101
#define SQLITE_INTEGER 1
#define SQLITE_FLOAT 2
#define SQLITE_TEXT 3
#define SQLITE_BLOB 4
#define SQLITE_NULL 5
#define SQLITE_OPEN_READONLY 0x1
#define SQLITE_OPEN_READWRITE 0x2
#define SQLITE_OPEN_CREATE 0x4
#define SQLITE_TRANSIENT ((void (*)(void *))-1)

typedef struct sqlite3 sqlite3;
typedef struct sqlite3_stmt sqlite3_stmt;

/* X(name, return type, argument list) — every symbol the engine may use. */
#define SQLDL_SYMBOLS(X)                                                       \
  X(sqlite3_libversion, const char *, (void))                                  \
  X(sqlite3_open_v2, int, (const char *, sqlite3 **, int, const char *))       \
  X(sqlite3_close_v2, int, (sqlite3 *))                                        \
  X(sqlite3_errmsg, const char *, (sqlite3 *))                                 \
  X(sqlite3_exec, int,                                                         \
    (sqlite3 *, const char *, void *, void *, char **))                        \
  X(sqlite3_free, void, (void *))                                              \
  X(sqlite3_prepare_v2, int,                                                   \
    (sqlite3 *, const char *, int, sqlite3_stmt **, const char **))            \
  X(sqlite3_step, int, (sqlite3_stmt *))                                       \
  X(sqlite3_reset, int, (sqlite3_stmt *))                                      \
  X(sqlite3_clear_bindings, int, (sqlite3_stmt *))                             \
  X(sqlite3_finalize, int, (sqlite3_stmt *))                                   \
  X(sqlite3_bind_null, int, (sqlite3_stmt *, int))                             \
  X(sqlite3_bind_int64, int, (sqlite3_stmt *, int, int64_t))                   \
  X(sqlite3_bind_double, int, (sqlite3_stmt *, int, double))                   \
  X(sqlite3_bind_text, int,                                                    \
    (sqlite3_stmt *, int, const char *, int, void (*)(void *)))                \
  X(sqlite3_bind_blob, int,                                                    \
    (sqlite3_stmt *, int, const void *, int, void (*)(void *)))                \
  X(sqlite3_column_count, int, (sqlite3_stmt *))                               \
  X(sqlite3_column_type, int, (sqlite3_stmt *, int))                           \
  X(sqlite3_column_int64, int64_t, (sqlite3_stmt *, int))                      \
  X(sqlite3_column_double, double, (sqlite3_stmt *, int))                      \
  X(sqlite3_column_text, const unsigned char *, (sqlite3_stmt *, int))         \
  X(sqlite3_column_blob, const void *, (sqlite3_stmt *, int))                  \
  X(sqlite3_column_bytes, int, (sqlite3_stmt *, int))                          \
  X(sqlite3_changes, int, (sqlite3 *))                                         \
  X(sqlite3_last_insert_rowid, int64_t, (sqlite3 *))                           \
  X(sqlite3_get_autocommit, int, (sqlite3 *))

/* Optional symbols: absent in some backends, checked before use. */
#define SQLDL_OPTIONAL(X)                                                      \
  X(sqlite3_enable_load_extension, int, (sqlite3 *, int))                      \
  X(sqlite3_load_extension, int,                                               \
    (sqlite3 *, const char *, const char *, char **))

#define FIELD(name, ret, args) ret(*name) args;
typedef struct {
  void *handle;
  SQLDL_SYMBOLS(FIELD)
  SQLDL_OPTIONAL(FIELD)
} sqldl_lib;
#undef FIELD

typedef struct {
  sqldl_lib *lib;
  sqlite3 *db;
} sqldl_db;

typedef struct {
  sqldl_lib *lib;
  sqlite3 *db;
  sqlite3_stmt *stmt;
} sqldl_stmt;

#define Lib_val(v) (*((sqldl_lib **)Data_custom_val(v)))
#define Db_val(v) ((sqldl_db *)Data_custom_val(v))
#define Stmt_val(v) ((sqldl_stmt *)Data_custom_val(v))

static struct custom_operations lib_ops = {
    "elpilite.sqldl.lib",       custom_finalize_default,
    custom_compare_default,     custom_hash_default,
    custom_serialize_default,   custom_deserialize_default,
    custom_compare_ext_default, custom_fixed_length_default};

static struct custom_operations db_ops = {
    "elpilite.sqldl.db",        custom_finalize_default,
    custom_compare_default,     custom_hash_default,
    custom_serialize_default,   custom_deserialize_default,
    custom_compare_ext_default, custom_fixed_length_default};

static struct custom_operations stmt_ops = {
    "elpilite.sqldl.stmt",      custom_finalize_default,
    custom_compare_default,     custom_hash_default,
    custom_serialize_default,   custom_deserialize_default,
    custom_compare_ext_default, custom_fixed_length_default};

static void sql_fail(sqldl_lib *lib, sqlite3 *db, const char *what) {
  char buf[1024];
  const char *msg = (db && lib->sqlite3_errmsg) ? lib->sqlite3_errmsg(db) : "";
  snprintf(buf, sizeof buf, "%s: %s", what, msg ? msg : "");
  caml_failwith(buf);
}

/* sqldl_load : string -> lib * string list  (missing required symbols) */
value sqldl_load(value v_path) {
  CAMLparam1(v_path);
  CAMLlocal4(res, v_lib, missing, cell);
  void *h = dlopen(String_val(v_path), RTLD_NOW | RTLD_LOCAL);
  if (!h) caml_failwith(dlerror());
  sqldl_lib *lib = calloc(1, sizeof *lib);
  lib->handle = h;
  missing = Val_emptylist;
#define LOAD(name, ret, args)                                                  \
  lib->name = (ret(*) args)dlsym(h, #name);                                    \
  if (!lib->name) {                                                            \
    cell = caml_alloc(2, 0);                                                   \
    Store_field(cell, 0, caml_copy_string(#name));                             \
    Store_field(cell, 1, missing);                                             \
    missing = cell;                                                            \
  }
  SQLDL_SYMBOLS(LOAD)
#undef LOAD
#define LOAD_OPT(name, ret, args) lib->name = (ret(*) args)dlsym(h, #name);
  SQLDL_OPTIONAL(LOAD_OPT)
#undef LOAD_OPT
  v_lib = caml_alloc_custom(&lib_ops, sizeof(sqldl_lib *), 0, 1);
  Lib_val(v_lib) = lib; /* libraries live for the whole process */
  res = caml_alloc_tuple(2);
  Store_field(res, 0, v_lib);
  Store_field(res, 1, missing);
  CAMLreturn(res);
}

value sqldl_libversion(value v_lib) {
  CAMLparam1(v_lib);
  sqldl_lib *lib = Lib_val(v_lib);
  if (!lib->sqlite3_libversion) caml_failwith("sqlite3_libversion missing");
  CAMLreturn(caml_copy_string(lib->sqlite3_libversion()));
}

value sqldl_open(value v_lib, value v_path, value v_readonly) {
  CAMLparam3(v_lib, v_path, v_readonly);
  CAMLlocal1(v_db);
  sqldl_lib *lib = Lib_val(v_lib);
  sqlite3 *db = NULL;
  int flags = Bool_val(v_readonly)
                  ? SQLITE_OPEN_READONLY
                  : (SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE);
  int rc = lib->sqlite3_open_v2(String_val(v_path), &db, flags, NULL);
  if (rc != SQLITE_OK) {
    char buf[512];
    snprintf(buf, sizeof buf, "open %s: rc=%d %s", String_val(v_path), rc,
             db ? lib->sqlite3_errmsg(db) : "");
    if (db) lib->sqlite3_close_v2(db);
    caml_failwith(buf);
  }
  v_db = caml_alloc_custom(&db_ops, sizeof(sqldl_db), 0, 1);
  Db_val(v_db)->lib = lib;
  Db_val(v_db)->db = db;
  CAMLreturn(v_db);
}

static sqldl_db *live_db(value v) {
  sqldl_db *d = Db_val(v);
  if (!d->db) caml_failwith("database is closed");
  return d;
}

value sqldl_close(value v_db) {
  CAMLparam1(v_db);
  sqldl_db *d = Db_val(v_db);
  if (d->db) {
    d->lib->sqlite3_close_v2(d->db);
    d->db = NULL;
  }
  CAMLreturn(Val_unit);
}

value sqldl_exec(value v_db, value v_sql) {
  CAMLparam2(v_db, v_sql);
  sqldl_db *d = live_db(v_db);
  char *err = NULL;
  int rc = d->lib->sqlite3_exec(d->db, String_val(v_sql), NULL, NULL, &err);
  if (rc != SQLITE_OK) {
    char buf[1024];
    snprintf(buf, sizeof buf, "exec: %s",
             err ? err : d->lib->sqlite3_errmsg(d->db));
    if (err) d->lib->sqlite3_free(err);
    caml_failwith(buf);
  }
  CAMLreturn(Val_unit);
}

value sqldl_prepare(value v_db, value v_sql) {
  CAMLparam2(v_db, v_sql);
  CAMLlocal1(v_stmt);
  sqldl_db *d = live_db(v_db);
  sqlite3_stmt *st = NULL;
  int rc = d->lib->sqlite3_prepare_v2(d->db, String_val(v_sql),
                                      caml_string_length(v_sql), &st, NULL);
  if (rc != SQLITE_OK || !st) sql_fail(d->lib, d->db, "prepare");
  v_stmt = caml_alloc_custom(&stmt_ops, sizeof(sqldl_stmt), 0, 1);
  Stmt_val(v_stmt)->lib = d->lib;
  Stmt_val(v_stmt)->db = d->db;
  Stmt_val(v_stmt)->stmt = st;
  CAMLreturn(v_stmt);
}

static sqldl_stmt *live_stmt(value v) {
  sqldl_stmt *s = Stmt_val(v);
  if (!s->stmt) caml_failwith("statement is finalized");
  return s;
}

value sqldl_finalize(value v_stmt) {
  CAMLparam1(v_stmt);
  sqldl_stmt *s = Stmt_val(v_stmt);
  if (s->stmt) {
    s->lib->sqlite3_finalize(s->stmt);
    s->stmt = NULL;
  }
  CAMLreturn(Val_unit);
}

value sqldl_reset(value v_stmt) {
  CAMLparam1(v_stmt);
  sqldl_stmt *s = live_stmt(v_stmt);
  s->lib->sqlite3_reset(s->stmt);
  s->lib->sqlite3_clear_bindings(s->stmt);
  CAMLreturn(Val_unit);
}

/* OCaml: type value = Null | Int of int64 | Float of float | Text of string
                     | Blob of string
   Null is the immediate 0; the others are blocks with tags 0..3. */
value sqldl_bind(value v_stmt, value v_idx, value v_val) {
  CAMLparam3(v_stmt, v_idx, v_val);
  sqldl_stmt *s = live_stmt(v_stmt);
  int i = Int_val(v_idx), rc;
  if (Is_long(v_val)) {
    rc = s->lib->sqlite3_bind_null(s->stmt, i);
  } else {
    value x = Field(v_val, 0);
    switch (Tag_val(v_val)) {
    case 0: rc = s->lib->sqlite3_bind_int64(s->stmt, i, Int64_val(x)); break;
    case 1: rc = s->lib->sqlite3_bind_double(s->stmt, i, Double_val(x)); break;
    case 2:
      rc = s->lib->sqlite3_bind_text(s->stmt, i, String_val(x),
                                     caml_string_length(x), SQLITE_TRANSIENT);
      break;
    default:
      rc = s->lib->sqlite3_bind_blob(s->stmt, i, String_val(x),
                                     caml_string_length(x), SQLITE_TRANSIENT);
    }
  }
  if (rc != SQLITE_OK) sql_fail(s->lib, s->db, "bind");
  CAMLreturn(Val_unit);
}

/* sqldl_step : stmt -> bool   (true = row available, false = done) */
value sqldl_step(value v_stmt) {
  CAMLparam1(v_stmt);
  sqldl_stmt *s = live_stmt(v_stmt);
  int rc = s->lib->sqlite3_step(s->stmt);
  if (rc == SQLITE_ROW) CAMLreturn(Val_true);
  if (rc == SQLITE_DONE) CAMLreturn(Val_false);
  sql_fail(s->lib, s->db, "step");
  CAMLreturn(Val_false);
}

value sqldl_column_count(value v_stmt) {
  CAMLparam1(v_stmt);
  CAMLreturn(Val_int(live_stmt(v_stmt)->lib->sqlite3_column_count(
      live_stmt(v_stmt)->stmt)));
}

value sqldl_column(value v_stmt, value v_idx) {
  CAMLparam2(v_stmt, v_idx);
  CAMLlocal2(res, x);
  sqldl_stmt *s = live_stmt(v_stmt);
  int i = Int_val(v_idx);
  switch (s->lib->sqlite3_column_type(s->stmt, i)) {
  case SQLITE_INTEGER:
    x = caml_copy_int64(s->lib->sqlite3_column_int64(s->stmt, i));
    res = caml_alloc(1, 0);
    Store_field(res, 0, x);
    break;
  case SQLITE_FLOAT:
    x = caml_copy_double(s->lib->sqlite3_column_double(s->stmt, i));
    res = caml_alloc(1, 1);
    Store_field(res, 0, x);
    break;
  case SQLITE_TEXT: {
    const unsigned char *t = s->lib->sqlite3_column_text(s->stmt, i);
    int n = s->lib->sqlite3_column_bytes(s->stmt, i);
    x = caml_alloc_initialized_string(n, (const char *)t);
    res = caml_alloc(1, 2);
    Store_field(res, 0, x);
    break;
  }
  case SQLITE_BLOB: {
    const void *b = s->lib->sqlite3_column_blob(s->stmt, i);
    int n = s->lib->sqlite3_column_bytes(s->stmt, i);
    x = caml_alloc_initialized_string(n, (const char *)b);
    res = caml_alloc(1, 3);
    Store_field(res, 0, x);
    break;
  }
  default:
    res = Val_int(0);
  }
  CAMLreturn(res);
}

value sqldl_changes(value v_db) {
  CAMLparam1(v_db);
  sqldl_db *d = live_db(v_db);
  CAMLreturn(Val_int(d->lib->sqlite3_changes(d->db)));
}

value sqldl_last_insert_rowid(value v_db) {
  CAMLparam1(v_db);
  sqldl_db *d = live_db(v_db);
  CAMLreturn(caml_copy_int64(d->lib->sqlite3_last_insert_rowid(d->db)));
}

value sqldl_autocommit(value v_db) {
  CAMLparam1(v_db);
  sqldl_db *d = live_db(v_db);
  CAMLreturn(Val_bool(d->lib->sqlite3_get_autocommit(d->db)));
}

value sqldl_load_extension(value v_db, value v_path) {
  CAMLparam2(v_db, v_path);
  sqldl_db *d = live_db(v_db);
  if (!d->lib->sqlite3_enable_load_extension || !d->lib->sqlite3_load_extension)
    caml_failwith("backend does not support loadable extensions");
  d->lib->sqlite3_enable_load_extension(d->db, 1);
  char *err = NULL;
  int rc = d->lib->sqlite3_load_extension(d->db, String_val(v_path), NULL, &err);
  if (rc != SQLITE_OK) {
    char buf[1024];
    snprintf(buf, sizeof buf, "load_extension: %s", err ? err : "");
    if (err) d->lib->sqlite3_free(err);
    caml_failwith(buf);
  }
  CAMLreturn(Val_unit);
}
