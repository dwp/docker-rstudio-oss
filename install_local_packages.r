PACKAGES_PATH=Sys.getenv("PACKAGES_PATH", unset="/mnt/packages/r")
USER_LIB_PATH=Sys.getenv("USER_LIB_PATH", unset=paste0("/home/", Sys.getenv("USER"), "/.rpckg"))

packages <- list.files(path=PACKAGES_PATH)
library(devtools)
library(stringr)

is_installed <- function(package){
    require(str_replace(package, "(.*?)\\..*$", replacement="\\1"), character.only = TRUE)
}

dir.create(USER_LIB_PATH, showWarnings = FALSE)

for(pck in packages){
    if(!is_installed(pck)) {
        install_local(paste0(PACKAGES_PATH, "/", pck), lib=USER_LIB_PATH)
        
        if(is_installed(pck)){
            print(paste0("Successfuly installed package: ", pck))
        } else{
            print(paste0("Failed to install package: ", pck))
        }
    }
}

