get_spark <- function(){
    httr::set_config(httr::config(ssl_verifypeer = 0L, ssl_verifyhost = 0L))
    conf <- sparklyr::spark_config(file = paste0("/home/", Sys.getenv("USER"),
                                     "/.spark_config.yml"))
    conf <- sparklyr::livy_config(conf = conf, proxy_user = Sys.getenv("USER"),
                                executor_cores = 2, custom_headers = list(Authorization = Sys.getenv("JWT_TOKEN")))
    sparklyr::spark_connect(method = "livy", version = Sys.getenv("SPARK_VERSION", unset="2.4.4"), config = conf)
}


get_hive <- function(){
    DBI::dbConnect(odbc::odbc(), dsn="DataWorks-Hive", UID=Sys.getenv("USER"), PWD=Sys.getenv("JWT_TOKEN"))
}
