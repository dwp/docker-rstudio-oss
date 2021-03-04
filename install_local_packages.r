PACKAGES_PATH=Sys.getenv("PACKAGES_PATH", unset="/mnt/packages/r")
USER_LIB_PATH=Sys.getenv("USER_LIB_PATH", unset=paste0("/home/", Sys.getenv("USER"), "/.rpckg"))

packages <- list.files(path=PACKAGES_PATH)
library(devtools)
library(stringr)
library(desc)

dir.create(USER_LIB_PATH, showWarnings = FALSE)

should_install <- function(package){
    installed_packages <- installed.packages()
    package_name <- str_replace(package, "(.*?)\\..*$", replacement="\\1")

    if(!(package_name %in% installed_packages)){
        print(paste0("Package ", package_name, " not currently installed. Installing..."))
        return(TRUE)
    }

    tmp_extract_path <- paste0("/tmp/pckg-install/")
    dir.create(tmp_extract_path, showWarnings = FALSE)
    untar(package, files = paste0(package_name, "/DESCRIPTION"), exdir=tmp_extract_path)

    desc <- description$new(file=paste0(tmp_extract_path, package_name))
    new_package_version <- toString(desc$get_version())
    installed_package_version <- toString(installed_packages[package_name,  "Version"])

    print(paste0(package_name, " - Installed package version: ", installed_package_version, ". New package version: ", new_package_version))

    if(compareVersion(installed_package_version, new_package_version) == -1){
        print(paste0("Package ", package_name, " is newer. Installing..."))
        return(TRUE)
    } else {
        print(paste0("Package ", package_name, " is same version or older. Not installing."))
        return(FALSE)
    }
}

for(pck in packages){
    if(should_install(pck)) {
        install_local(paste0(PACKAGES_PATH, "/", pck), lib=USER_LIB_PATH)
    }
}

