# Query GCAM database
#
# Hassan Niazi, October 2024

library(rgcam)

# query-specific configuration
dbLoc   <- "../../output/"
dbNames <- c("database_basexdb")  # add more databases if needed
scenarioName <- c("Reference")    # add more scenarios if needed
queryFile   <- "queries.xml"  # specify the query file
outFile     <- "gcam_output.proj"

WRITE_CSVS <- TRUE

# execute the quering process
for (db in dbNames) {
  conn <- localDBConn(dbLoc, db)
  prj <- addScenario(conn, outFile, scenarioName, queryFile)
}

# load the project data
projData <- loadProject(prj)

# check scenarios and queries in the queried data
listScenarios(projData)
listQueries(projData)

# get queries from the project data
# q_popByRegion <- getQuery(projData, 'population by region')
# q_elecGenByGenTech <- getQuery(projData,'elec gen by gen tech and cooling tech')


# write scenarios data as csvs. Usage: write_query_csvs("im3scen_water")
write_query_csvs <- function(project, write_scen_query = FALSE, zip_csvs = F) {
  if (exists({{project}}, envir = .GlobalEnv)) {
    prj <- get({{project}}, envir = .GlobalEnv)
  } else {
    prj <- loadProject(proj = paste0({{project}}, ".proj"))
  }

  output_dir <- file.path(project)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  print(paste0("Writing ", project, " data to ", output_dir))
  
  if (write_scen_query == TRUE) {
    # write each scenario, each query in a separate file
    for (scen in listScenarios(prj)) {
      for (query in listQueries(prj)) {
        file_ext <- if (zip_csvs == TRUE) ".csv.gz" else ".csv"
        file_path <- file.path(output_dir, paste0(scen, "_", query, file_ext))
        readr::write_csv(prj[[scen]][[query]], file = file_path)
      }
    }
  } else {
    # all scenarios for a query in one file
    for (query in listQueries(prj)) {
      file_ext <- if (zip_csvs == TRUE) ".csv.gz" else ".csv"
      file_path <- file.path(output_dir, paste0(query, file_ext))
      readr::write_csv(getQuery(prj, query), file = file_path)
    }
  }
}


if (WRITE_CSVS) {
  write_query_csvs(gsub("\\.proj$", "", outFile))
}

# zip the CSV folder
zip(zipfile = paste0(gsub("\\.proj$", "", outFile), ".zip"), files = gsub("\\.proj$", "", outFile))