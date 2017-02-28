#!/bin/ksh

requiredChecks()
{ 
   inputFile="$1"
   CSSFile="$2"
   reportTitle="$3"
   delimiterChar="$4"

echo "ReportTitle = $3"
   msg1a="Required input text file name not defined exiting."
   msg1b="Required input text file \""${inputFile}"\" not present cannot continue exiting."
   msg2a="Required CSS file name not defined exiting."
   msg2b="Required CSS file \""${CSSFile}"\" not present cannot continue exiting."
   msg3a="Required report title not defined exiting."
   msg3b="Required report title is empty string exiting."
   msg4a="Delimiter Char is not defined exiting."
   msg4b="Delimiter Char is empty string exiting."

   [ "${inputFile}" ] ||  echo "${msg1a}"
   [ "${inputFile}" ] ||  exit 1

   [ -f "${inputFile}" ] || echo "${msg1b}"
   [ -f "${inputFile}" ] || exit 1

   [ "${CSSFile}" ] || echo "${msg2a}"
   [ "${CSSFile}" ] || exit 1

   [ -f "${CSSFile}" ] || echo "${msg2b}"
   [ -f "${CSSFile}" ] || exit 1


   [ "${reportTitle}" ] || echo "${msg3a}"
   [ "${reportTitle}" ] || exit 1

   [ -z "${reportTitle}" ] && echo "${msg3b}"
   [ -z "${reportTitle}" ] && exit 1


   [ "${delimiterChar}" ] || echo "${msg4a}"
   [ "${delimiterChar}" ] || exit 1

   [ -z "${delimiterChar}" ] && echo "${msg4b}"
   [ -z "${delimiterChar}" ] && exit 1
}

cleanUpTextFile()
{
  inputFile="$1"
  cleanedInputFile=`echo "${inputFile}" | cut -f1 -d"."`.tmp
  delimiterChar="$2"
  awk -F"${delimiterChar}" -v delimiter="${delimiterChar}" '{
                #Remove trailing white space from the end of each field
                gsub("[[:space:]]*$","",$1)
                gsub("[[:space:]]*$","",$2)
                gsub("[[:space:]]*$","",$3)
                gsub("[[:space:]]*$","",$4)
                gsub("[[:space:]]*$","",$5)
                gsub("[[:space:]]*$","",$6)
                gsub("[[:space:]]*$","",$7)

                #Remove all numbers from description field
                if (substr($3, 1, 9) == "CHECK NO.")
                   ;
                else
                   gsub("[0-9]*","",$3)

                #Remove leading dashes from description field
                gsub("^-*","",$3)

               #Remove all # from description field
                gsub("#*","",$3)

               #Remove leading / from description field
                gsub("^/*","",$3)

                #Remove leading spaces from description field
                gsub("^[[:space:]]*","",$3)

                #Convert to all fields to uppercase
                $1=toupper($1)
                $2=toupper($2)
                $3=toupper($3)
                $4=toupper($4)
                $5=toupper($5)
                $6=toupper($6)
                $7=toupper($7)

                #Add leading zero for dates with 1 character
                split($2, d, "/");
                month=d[1];
                day=d[2];
                year=d[3];
                if(length(month) < 2) {
                   month = "0" month
                }
                if(length(day) < 2) {
                   day = "0" day
                }
                date = month "/" day "/" year
                $2 = date
                print $1 delimiter $2 delimiter $3 delimiter $4 delimiter $5 delimiter $6 delimiter $7
                }'  "${inputFile}" > "${cleanedInputFile}"
}


sortTextFile()
{
   inputFile="$cleanedInputFile"
   sortedOutputFile=`echo "${inputFile}" | cut -f1 -d"."`.srt
   delimiterChar="$2"

   #Field 3 is Desc, Field 2 is Date
   sort -t "${delimiterChar}" -k3,3 -k2,2r -o "${sortedOutputFile}" "${inputFile}"
}

buildHTMLFile()
{
   HTMLFile=`echo "$1" | cut -f1 -d"."`.html
   H1Title="$2"

   echo "<!DOCTYPE html>" > ${HTMLFile}

   echo "<html>" >> ${HTMLFile}


   echo "<head><h1>${H1Title}</h1></head>" >> ${HTMLFile}
}

buildStyleSheet()
{
   HTMLFile="$1"
   CSSFile="$2"

   while read line
   do
      # display $line or do somthing with $line
      echo "$line" >> ${HTMLFile}
   done < ${CSSFile}
}

buildTable()
{
   sortedOutputFile="$1"
   HTMLFile="$2"
   delimiterChar="$3"

   awk -F "${delimiterChar}" 'BEGIN { print "<body><table id=\"customers\"><tr>" \
                           "<th>Line</th>" \
                           "<th>Transaction Type</th>" \
                           "<th>Date</th>" \
                           "<th>Description</th>"  \
                           "<th>Memo</th>" \
                           "<th>Amount</th>" 
                           subtotal = 0.00 }

       {
       if (NR == 1)
           LINE_NBR = 1
 
       if (LINE_NBR % 2 == 0) {
         CLASS="";
       }
       else {
         CLASS="class=\"alt\"";
       }

       
       if (NR == 1) {
          prevDesc=$3;
          currDesc=$3;
       }
       else {
          currDesc=$3;
       }

       #description[$5] += $7


       if ((prevDesc == currDesc) || ((substr(prevDesc, 1, 9) == "CHECK NO.") && (substr(currDesc, 1, 9) == "CHECK NO."))) {
           subtotal=subtotal + $5;
           printf ("%s%s%s%u%s%s%s%s%s%s%s%s%s%'"'"'7.2f%s",
                   "<tr ",CLASS,"><td>",LINE_NBR,".</td><td>",
                                $1,"</td><td>",$2,"</td><td>",$3,"</td><td>",
                                $4,"</td><td style=\"text-align:right\">",$5,"</td><tr>\n")
                currDesc=$3;
                LINE_NBR = LINE_NBR + 1
       }
       else {
           printf ("%s%s%s%u%s%s%s$%'"'"'7.2f%s%s", 
                   "<tr ",CLASS,"><td>",LINE_NBR,".</td><td></td>",
                   "<td></td><td></td><td></td>","<td style=\"text-align:right\">",
                    subtotal,"</td>","</tr>\n")
           LINE_NBR = LINE_NBR + 1
           printf ("%s%s%s%u%s%s%s",
                        "<tr ",CLASS,"><td>",LINE_NBR,".</td><td></td>",
                        "<td></td><td></td><td></td><td></td>",
                        "</tr>\n")
           subtotal=$5;
           LINE_NBR = LINE_NBR + 1
           printf ("%s%s%s%u%s%s%s%s%s%s%s%s%s%'"'"'7.2f%s",
                        "<tr ",CLASS,"><td>",LINE_NBR,".</td><td>",
                        $1,"</td><td>",$2,"</td><td>",$3,"</td><td>",
                        $4,"</td><td style=\"text-align:right\">",$5,"</td></tr>\n")
           prevDesc=$3;
           LINE_NBR = LINE_NBR + 1
       }
       }
       END   {
                printf ("%s%s%s%s%s%s%s$%'"'"'7.2f%s%s",
                        "<tr ",CLASS,"><td>",LINE_NBR,"</td><td></td>",
                        "<td></td><td></td><td></td>","<td>",
                        subtotal,"</td>","</tr>\n")

                  print "</table></body>" 
             }' "${sortedOutputFile}" >> "${HTMLFile}"

   echo "</html>" >> "${HTMLFile}"
}

#Begin Script
inputFile="$1"
styleSheet="$2"
title="$3"
delimiter="$4"

requiredChecks "${inputFile}" "${styleSheet}" "${title}" "${delimiter}"
cleanUpTextFile "${inputFile}" "${delimiter}"
sortTextFile "${cleanedInputFile}" "${delimiter}"
buildHTMLFile "${inputFile}" "${title}"
buildStyleSheet "${HTMLFile}" "${styleSheet}"
buildTable "${sortedOutputFile}" "${HTMLFile}" "${delimiter}"
#put.sh a6kckjs1.mckesson.com reid reid ${HTMLFile}

#rm "${cleanedInputFile}" "${sortedOutputFile}"
