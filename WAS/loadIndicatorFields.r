# The MIT License (MIT)
# Copyright (c) 2017 Louise AC Millard, MRC Integrative Epidemiology Unit, University of Bristol
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
# documentation files (the "Software"), to deal in the Software without restriction, including without 
# limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of 
# the Software, and to permit persons to whom the Software is furnished to do so, subject to the following 
# conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions 
# of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
# TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
# DEALINGS IN THE SOFTWARE.

##
## load data used for data code default value related field, and categorical multiple indicator field
loadIndicatorFields <- function(phenosToTest) {

	print("Loading indicator fields from phenotypes file ...")

	# read pheno file column names
        phenoVarsAll = colnames(read.table(opt$phenofile, header=1, nrows=1, sep=','))
        phenoVarsAll = phenoVarsAll[which(phenoVarsAll!=opt$userId)]

	indVars = c(opt$userId)

	## add indicator variables to pheno data
	indVars = addIndicatorVariables(indVars, phenosToTest, phenoVarsAll)

	print(paste("Loading required indicator variable(s):", indVars[2:length(indVars)]))

        ## read in the right table columns
        data = fread(opt$phenofile, select=indVars, sep=',', header=TRUE, data.table=FALSE)

	data = data.frame(lapply(data,function(x) type.convert(as.character(x))))

	colnames(data)[1] <- "userID"
	return(data)

}


addIndicatorVariables <- function(indVars, phenosToTest, phenoVarsAll) {

	#####
	##### default value related fields for data codes
	# get list of all indicator variables from outcome info file

	# get datacodes with an indicator variable
	dataCodeIdx = which(!is.na(vl$dataCodeInfo$default_related_field))
	dataCodeWithRF = vl$dataCodeInfo[dataCodeIdx,]

#	print(dataCodeWithRF)

	defaultFields = c()

	# check there is a field in the phenotypes data for each data code and if so then add this data codes related field to the phenosToTest list
	for (i in 1:nrow(dataCodeWithRF)) {
		dc = dataCodeWithRF$dataCode[i]
		rf = dataCodeWithRF$default_related_field[i]
		rf = paste("x",rf,"_0_0", sep="")

		fieldsIdx = which(vl$phenoInfo$datacode == dc)
		fieldIDs = vl$phenoInfo$FIELD_ID[fieldsIdx]
		fieldIDs = paste("x",fieldIDs,"_0_0", sep="")
		
		# if one of these field IDs are in phenotypeColumns then data code related field is needed
		if (length(union(fieldIDs, phenosToTest))>0) {
			defaultFields = append(defaultFields, rf)
		}
	}

	defaultFields = unique(defaultFields)
	indVars = append(indVars, defaultFields)
	
	# whether there are any related fields that are not in the phenotype data file when they should be
	hasIssue=FALSE

	#####
	##### check these required variables exist in phenotype file
        if(length(defaultFields)>0) {
                for (i in 1:length(defaultFields)) {
                        if (!(defaultFields[i] %in% phenoVarsAll)) {
                                print(paste("Required variable: Field ",defaultFields[i],"is a data code related field (default_related_field column in data code information file) but was not found in phenotype data"))
                        	hasIssue=TRUE
			}
                }
        }

	#####
	##### categorical multiple indicator fields

	# get field info, for fields with cat mult indicator fields
        fieldsIdx = which(!is.na(vl$phenoInfo$CAT_MULT_INDICATOR_FIELDS))
        fieldsWithCMIF = vl$phenoInfo[fieldsIdx,]
        fieldsWithCMIF = fieldsWithCMIF[-which(fieldsWithCMIF$CAT_MULT_INDICATOR_FIELDS == "NO_NAN"),]
        fieldsWithCMIF = fieldsWithCMIF[-which(fieldsWithCMIF$CAT_MULT_INDICATOR_FIELDS == "ALL"),]
        fieldsWithCMIF = fieldsWithCMIF[-which(fieldsWithCMIF$CAT_MULT_INDICATOR_FIELDS == ""),]

	# turn into variable format not field ID
	fieldsWithCMIF$CAT_MULT_INDICATOR_FIELDS = paste("x",fieldsWithCMIF$CAT_MULT_INDICATOR_FIELDS,"_0_0", sep="")
	fieldsWithCMIF$FieldID = paste("x",fieldsWithCMIF$FieldID,"_0_0", sep="")

	# remove rows where the field isn't in the phenotypes list
	idxIn = which(fieldsWithCMIF$FieldID %in% phenosToTest)
	fieldsWithCMIF = fieldsWithCMIF[idxIn,]

	defaultFields = fieldsWithCMIF$CAT_MULT_INDICATOR_FIELDS
	defaultFields = unique(defaultFields)
        #####
	##### remove those that already exist in phenotypes 'part'
	idxExists = which(defaultFields %in% indVars)
	if (length(idxExists>0)) {
	        defaultFields = defaultFields[-idxExists]
	}
	
	#####
	##### check these required variables exist in phenotype file
	if(length(defaultFields)>0) {
		for (i in 1:length(defaultFields)) {
			if (!(defaultFields[i] %in% phenoVarsAll)) {
				print(paste("Required variable: Field ",defaultFields[i],"is a categorical multiple indicator field (CAT_MULT_INDICATOR_FIELDS column in variable information file) but was not found in phenotype data")) 
				hasIssue=TRUE
			}
		}
	}


	# stop script if there are missing variables
	if (hasIssue==TRUE) {
		print("!!! PHESANT has stopped - add required variables to phenotype file or remove relevant phenotypes (so that required variables are not needed).")
		quit()
	}
	
        indVars = unique(append(indVars, defaultFields))

	return(indVars)

}
