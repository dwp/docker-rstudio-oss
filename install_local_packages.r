PACKAGES_PATH <- Sys.getenv("PACKAGES_PATH", unset = "/mnt/packages/r")
USER_LIB_PATH <- Sys.getenv("USER_LIB_PATH", unset = paste0("/home/", Sys.getenv("USER"), "/.rpckg"))

packages <- list.files(path = PACKAGES_PATH)
library(desc)

dir.create(USER_LIB_PATH, showWarnings = FALSE)
tmp_work_path <- paste0("/tmp/pckg-install/")
dir.create(tmp_work_path, showWarnings = FALSE)

should_install <- function(package) {
  installed_packages <- installed.packages()
  package_name <- stringr::str_replace(package, "(.*?)\\..*$", replacement = "\\1")

  if (!(package_name %in% installed_packages)) {
    print(paste0("Package ", package_name, " not currently installed. Installing..."))
    return(TRUE)
  }

  untar(paste0(PACKAGES_PATH, "/", package), files = paste0(package_name, "/DESCRIPTION"), exdir = tmp_work_path)

  desc <- description$new(file = paste0(tmp_work_path, package_name))
  new_package_version <- toString(desc$get_version())
  installed_package_version <- toString(installed_packages[package_name, "Version"])

  print(paste0(package_name, " - Installed package version: ", installed_package_version, ". New package version: ", new_package_version))

  if (compareVersion(installed_package_version, new_package_version) == -1) {
    print(paste0("Package ", package_name, " is newer. Installing..."))
    return(TRUE)
  } else {
    print(paste0("Package ", package_name, " is same version or older. Not installing."))
    return(FALSE)
  }
}

for (pck_file in packages) {
  if (should_install(pck_file)) {
    pckg_path <- paste0(PACKAGES_PATH, "/", pck_file)
    untar(pckg_path, exdir = tmp_work_path)
    extracted_name <- stringr::str_replace(pck_file, "(.*?)\\..*$", replacement = "\\1")
    devtools::document(paste0(tmp_work_path, extracted_name))
    install.packages(paste0(tmp_work_path, extracted_name), repos = NULL, lib = USER_LIB_PATH, INSTALL_opts = '--no-lock')
  }
}

