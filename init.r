tmp_env <- new.env(parent = emptyenv())

tmp_env$init <- function(){
  VARS_TO_SET <- list("JWT_TOKEN", "USER")

  env_vars <- readLines("/usr/local/lib/R/etc/Renviron")
  
  # Remove comments
  env_vars <- env_vars[lapply(env_vars, startsWith, "#") == FALSE]
  
  # Remove empty lines
  env_vars <- env_vars[env_vars != ""]
  
  kv_env_vars <- strsplit(env_vars, "=", fixed = TRUE)
  
  kv_to_set <- kv_env_vars[lapply(kv_env_vars, function(kv) kv[1] %in% VARS_TO_SET) == TRUE]
  
  lapply(kv_to_set, function(kv) {
    args = list(kv[2])
    names(args) = kv[1]
    do.call(Sys.setenv, args)
  })
}

tmp_env$init()
rm(tmp_env)
