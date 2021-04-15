#!/usr/bin/gawk -f 

BEGIN{

  # READ QUERY STRING
  split(ENVIRON["QUERY_STRING"], qs, "&")
  for (q in qs) {
    split(qs[q], qp, "=")
    f[qp[1]] = substr(urldecode(qp[2]),1,100)
  }

  # SEARCH
  if ((f["method"] == "search") &&              \
      (f["what"] || f["mat"])) {
    
    readdata()
    
    if (f["what"] && !f["mat"]) {
      for (i in What)
        if (What[i] ~ f["what"])
          list[i] = 1
    }
    else if (!f["what"] && f["mat"]) {
      for (i in What)
        if (Mat[i] ~ f["mat"])
          list[i] = 1
    }
    else {
      for (i in What)
        if ((What[i] ~ f["what"] ) &&  \
            (Mat[i] ~  f["mat"] ))
          list[i] = 1
    }

    # Filter
    if (f["site"])
      for (i in list)
        if (Site[i] != f["site"])
          list[i] = 0
            
    header("Search results")
    print "<h1>Search results</h1>"
    print "<p>Query:</p><ul>"
    if (f["what"])
      print "<li>Desc. = <i>" f["what"] "</i></li>"
    if (f["mat"])
      print "<li>material = <i>" f["mat"] "</i></li>"
    if (f["site"])
      print "<li>Limit by site = <i>" f["site"] "</i></li>"
    print "</ul>"
    
    print "<table>"
    print "<tr><th>GUID</th><th>Year</th><th>Desc.</th><th>Material</th><th>Site</th></tr>"

    PROCINFO["sorted_in"] = "@val_str_asc"
    for (i in What) {
      if (list[i]) {
        print "<tr>"
        print "<td><a href=\"do?method=detail&amp;guid=" i "\">" i "</a></td>"
        print "<td>" Year[i] "</td>"
        print "<td>" What[i] "</td>"
        print "<td>" Mat[i]  "</td>"
        print "<td>" Site[i]  "</td>"
        print "</tr>"
      }
    }
    print "</table>"
    print "<p>[ <a href=\"do\">BACK</a> ]</p>"
    footer()
  }

  # DETAILS
  else if ((f["method"] == "detail") && f["guid"]) {

    readdata()
    
    header("Details: " f["guid"])
    
    print "<h1>" f["guid"] "</h1>"
    print "<table>"
    print "<tr><td>Description:"   "</td><td style=\"font-weight:bold;\">" What[f["guid"]]    "</td></tr>"
    print "<tr><td>Material:"      "</td><td style=\"font-weight:bold;\">" Mat[f["guid"]]     "</td></tr>"
    print "<tr><td>Year:"          "</td><td>" Year[f["guid"]]    "</td></tr>"
    print "<tr><td>Site:"          "</td><td>" Site[f["guid"]]     "</td></tr>"
    print "<tr><td>AHRS Survey:"       "</td><td>" AHRS[f["guid"]] "</td></tr>"
    print "<tr><td>Quad:"          "</td><td>" Loc[f["guid"]]     "</td></tr>"
    print "<tr><td>Quadrant:"      "</td><td>" Quad[f["guid"]]    "</td></tr>"
    print "<tr><td>Square:"        "</td><td>" Square[f["guid"]]    "</td></tr>"
    print "<tr><td>Stratigraphy:"  "</td><td>" Strat[f["guid"]]   "</td></tr>"
    print "<tr><td>Collected by:"  "</td><td>" Coll[f["guid"]]    "</td></tr>"
    print "<tr><td>Identified by:" "</td><td>" IDby[f["guid"]]    "</td></tr>"
    print "<tr><td>Preparator:"    "</td><td>" Prep[f["guid"]]    "</td></tr>"
    print "</table>"
    print "<p>[ <a href=\"https://arctos.database.museum/guid/" f["guid"] \
      "\">See on ARCTOS</a> ]</p>"
    print "<p>[ <a href=\"do\">HOME</a> ]</p>"

    footer()
    
  }

  # LISTS
  else if ((f["method"] == "list") && f["term"]) {
    
    readdata()

    if (f["term"] == "what")
      termtext = "Description"
    else if (f["term"] == "mat")
      termtext = "Material"
    else if (f["term"] == "site")
      termtext = "Site"
    else
      termtext = "Other"
    
    header("Term list: " termtext)
    
    print "<h1>Term list: '" termtext "'</h1>"
    print "<ul>"
    PROCINFO["sorted_in"] = "@ind_str_asc"
    if (f["term"] == "what")
      for (i in WhatList)
        print "<li><a href=\"do?method=search&amp;what=%5E" i "%24\">" i "</a> (" \
          WhatList[i] ")</li>"
    else if (f["term"] == "mat")
      for (i in MatList)
        print "<li><a href=\"do?method=search&amp;mat=%5E" i "%24\">" i "</a> (" \
          MatList[i] ")</li>"
    else if (f["term"] == "site")
      for (i in SiteList)
        print "<li>" i " (" SiteList[i] ")</li>"
    print "<ul>"
    
    footer()
    
  }

  else {

    readdata()

    header("Wales collections")
    
    print "<h1>Wales collections</h1>"
    print "<form action=\"do\">"
    print "<input type=\"hidden\" name=\"method\" value=\"search\"/>"
    print "<table>"
    print "<tr><td>Description search term: "                       \
      "(<a href=\"do?method=list&amp;term=what\">list</a>)</td><td>"    \
      "<input type=\"text\" name=\"what\"/></td></tr>"
    print "<tr><td>Material search term: "                       \
      "(<a href=\"do?method=list&amp;term=mat\">list</a>)</td><td>"  \
      "<input type=\"text\" name=\"mat\"/></td></tr>"
    print "<tr><td>Limit by site: </td><td>"                            \
      "<select name=\"site\" autocomplete=\"off\">"                     \
      "<option value=\"\" selected=\"selected\"></option>"
    PROCINFO["sorted_in"] = "@ind_str_asc"
    for (i in SiteList)
      print "<option value=\"" i "\">" i "</option>"
    print "</select></td></tr>"
    print "</table>"
    print "<p>Search terms: plain text, or <a href=\"https://www.gnu.org/software/gawk/manual/gawk.html#Regexp\">regular expression</a>.<br/>Entering both Description and Material terms implies AND.</p>"
    print "<br/><input type=\"submit\" value=\"Search\"/>"
    
    print "</form>"
    footer()
    
  }
    
  exit 1
}

function header(title) {
  # version history: [chars app] -> [tcm app] -> here
  
  print "Content-type: text/html\n\n"                                   \
    "<!DOCTYPE html>"                                                   \
    "<html xmlns=\"http://www.w3.org/1999/xhtml\">"                     \
    "<head><title>" title "</title>"                                    \
    "<meta http-equiv=\"Content-Type\" content=\"text/html;"            \
    "charset=utf-8\" />"                                                \
    "<link href=\"https://handbook.arctosdb.org/images/favicon64.png\" " \
    "rel=\"shortcut icon\" type=\"image/png\"/>"                        \
    "<style type=\"text/css\">"                                         \
    "body { font-size: 14px; font-family: 'Montserrat', "               \
    "Verdana, Arial, Helvetica, sans-serif; }"                          \
    ".main {width: 1000px; padding-top: 10px; margin-left: auto;"       \
    "  margin-right: auto; }"                                           \
    "h1 { padding-top:20px; }"                                          \
    "select , option { font-size: 14px }"                               \
    "table { border-collapse: collapse }"                               \
    "td, th { border: 1px solid black; padding: 5px }"                  \
    "a { color:#15358d; text-decoration:none; border-bottom-style:none }" \
    "a:visited { color:#9f1dbc }"                                       \
    "a:hover {color:#15358d; border-bottom-style:solid; "               \
    "border-bottom-width:thin }"                                        \
    ".graph { max-width: 100%; }"                                       \
    "</style>"                                                          \
    "</head>\n<body>\n"                                                   \
    "<div class=\"main\">"

  # "<link href=\"https://fonts.googleapis.com/css?family=Montserrat\" "  \
  #  "rel=\"stylesheet\"/>"                                              \


}

function footer() {
  print "</div>\n</body>\n</html>";
}

function urldecode(text,   hex, i, hextab, decoded, len, c, c1, c2, code) {
# decode urlencoded string
# urldecode function from Heiner Steven
#   http://www.shelldorado.com/scripts/cmds/urldecode
# version 1
	
  split("0 1 2 3 4 5 6 7 8 9 a b c d e f", hex, " ")
  for (i=0; i<16; i++) hextab[hex[i+1]] = i
  
  decoded = ""
  i = 1
  len = length(text)
  
  while ( i <= len ) {
    c = substr (text, i, 1)
    if ( c == "%" ) {
      if ( i+2 <= len ) {
        c1 = tolower(substr(text, i+1, 1))
        c2 = tolower(substr(text, i+2, 1))
        if ( hextab [c1] != "" || hextab [c2] != "" ) {
          # print "Read: %" c1 c2;
          # Allow: 
          # 20 begins main chars, but dissallow 7F (wrong in orig code!)
          #   tab, newline, formfeed, carriage return
          if ( ( (c1 >= 2) && ((c1 c2) != "7f") )   \
               || (c1 == 0 && c2 ~ "[9acd]") )
            {
              code = 0 + hextab [c1] * 16 + hextab [c2] + 0
              # print "Code: " code
              c = sprintf ("%c", code)
            } else {
            # for dissallowed chars
            c = " "
          }
          i = i + 2
        }
      }
    } else if ( c == "+" ) 	# special handling: "+" means " "
      c = " "
    decoded = decoded c
    ++i
  }
  
  # change linebreaks to \n
  gsub(/\r\n/, "\n", decoded);
  # remove last linebreak
  gsub(/[\n\r]*$/,"",decoded);
  return decoded
}

function readdata() {
  
  FS = "|"
  while((getline < "data") > 0) {

    AHRS[$1] = $2
    Site[$1]    = $3
    Year[$1]    = $4
    What[$1]    = $5
    Mat[$1]     = $6
    Loc[$1]     = $7
    Strat[$1]   = $11
    Quad[$1]    = $12
    Square[$1]    = $13
    Coll[$1]    = $14
    IDby[$1]    = $15
    Prep[$1]    = $16

    WhatList[$5]++
    MatList[$6]++
    SiteList[$3]++
  }
}
