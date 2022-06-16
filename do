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

    # Filters
    if (f["site"])
      for (i in list)
        if (Site[i] != f["site"])
          list[i] = 0

    if (f["ahrs"])
      for (i in list)
        if (AHRS[i] != f["ahrs"])
          list[i] = 0

    if (f["img"])
      for (i in list)
        if (!length(Media[i]))
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
    if (f["ahrs"])
      print "<li>Limit by AHRS ID = <i>" f["ahrs"] "</i></li>"
    print "</ul>"

    for (i in list)
      nlist += list[i]

    if (nlist) {
      print "<table>"
      print "<tr><th>ID</th><th>Description</th><th>Material</th><th>Year</th><th>Site</th><th>AHRS ID</th><th>Pics</th></tr>"

      PROCINFO["sorted_in"] = "@val_str_asc"
      for (i in What) {
        if (list[i]) {
          print "<tr>"
          print "<td><a href=\"do?method=detail&amp;guid=" i "\">" gensub(/^UAM:Arc:/,"","G",i) "</a></td>"
          print "<td><b>" What[i] "</b></td>"
          print "<td>" Mat[i]  "</td>"
          print "<td>" Year[i] "</td>"
          print "<td>" Site[i]  "</td>"
          print "<td>" AHRS[i]  "</td>"
          print "<td>" ((length(Media[i])) ? "✅" : "") "</td>"
          print "</tr>"
        }
      }
      print "</table>"
    }
    else
      print "<p><i>No results</i></p>"
    
    # print "<p>[ <a href=\"do\">BACK</a> ]</p>"
    footer()
  }

  # DETAILS
  else if ((f["method"] == "detail") && f["guid"]) {

    readdata()
    
    header("Details: " f["guid"])
    
    print "<h1>Object details</h1>"
    print "<table>"
    
    print "<tr><td>GUID:"          "</td><td>" f["guid"]    "&#160;&#160;&#160;(Go to <a href=\"https://arctos.database.museum/guid/" f["guid"] "\">ARCTOS</a>)"

    print (What[f["guid"]]) ?                                      \
      ("<tr><td>Description:</td><td style=\"font-weight:bold;\">" \
       What[f["guid"]] "</td></tr>") : ""

    print (Mat[f["guid"]]) ?                                    \
      ("<tr><td>Material:</td><td style=\"font-weight:bold;\">" \
       Mat[f["guid"]] "</td></tr>") : ""

    print "<tr><td>Year:"          "</td><td>" Year[f["guid"]]    "</td></tr>"
    print "<tr><td>Site:"          "</td><td>" Site[f["guid"]]     "</td></tr>"
    print "<tr><td>AHRS Survey:"       "</td><td>" AHRS[f["guid"]] "</td></tr>"
    print "<tr><td>Quad:"          "</td><td>" Loc[f["guid"]]     "</td></tr>"
    
    print (Quad[f["guid"]]) ? \
      ("<tr><td>Quadrant:</td><td>" Quad[f["guid"]]    "</td></tr>") : ""
    
    print (Square[f["guid"]]) ? \
      ("<tr><td>Square:</td><td>" Square[f["guid"]] "</td></tr>") : ""

    print (Strat[f["guid"]]) ?                                          \
      ("<tr><td>Stratigraphy:" "</td><td>" Strat[f["guid"]] "</td></tr>") : ""

    print "<tr><td>Collected by:"  "</td><td>" Coll[f["guid"]]    "</td></tr>"
    print "<tr><td>Identified by:" "</td><td>" IDby[f["guid"]]    "</td></tr>"

    print (Prep[f["guid"]]) ?                                           \
      ("<tr><td>Preparator:"    "</td><td>" Prep[f["guid"]] "</td></tr>") : ""

    if (length(Media[f["guid"]]))
      for (i = 1; i <= length(Media[f["guid"]]); i++)
        print "<tr><td>Image " i ":</td>"\
          "<td><img style=\"width:400px;border:thin silver solid;padding:10px;\" src=\"" Media[f["guid"]][i] \
          "\"/></td></tr>"

    print "</table>"
    # print "<p>[ <a href=\"https://arctos.database.museum/guid/" f["guid"] \
    #   "\">See on ARCTOS</a> ]</p>"
    # print "<p>[ <a href=\"do\">HOME</a> ]</p>"

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
    if (f["term"] == "what") {
      for (i in WhatList)
        if (i)
          print "<li><a href=\"do?method=search&amp;what=%5E" i "%24\">" i "</a> (" \
            WhatList[i] ")</li>"
    }
    else if (f["term"] == "mat") {
      for (i in MatList)
        if (i)
          print "<li><a href=\"do?method=search&amp;mat=%5E" i "%24\">" i "</a> (" \
            MatList[i] ")</li>"
    }
    else if (f["term"] == "site") {
      for (i in SiteList)
        if (i)
          print "<li>" i " (" SiteList[i] ")</li>"
    }
    print "<ul>"
    
    footer()
    
  }

  else {

    readdata()

    header("Wales archaeological collections")
    
    print "<h1>Wales archaeological collections</h1>"
    print "<p>Search the Wales, Alaska, archaeological collections the University of Alaska Museum of the North:</p>"
    print "<form action=\"do\">"
    print "<input type=\"hidden\" name=\"method\" value=\"search\"/>"
    print "<table>"
    print "<tr><td>Object description:</td><td>"    \
      "<input type=\"text\" name=\"what\"/></td><td>(<a href=\"do?method=list&amp;term=what\">list terms</a>)</td></tr>"
    print "<tr><td>Material:</td><td>"                                  \
      "<input type=\"text\" name=\"mat\"/></td><td>(<a href=\"do?method=list&amp;term=mat\">list terms</a>)</td></tr>"
    print "<tr><td>Limit by site:</td><td>"                            \
      "<select name=\"site\" autocomplete=\"off\" style=\"width:100%;\">" \
      "<option value=\"\" selected=\"selected\"></option>"
    PROCINFO["sorted_in"] = "@ind_str_asc"
    for (i in SiteList)
      print "<option value=\"" i "\">" i "</option>"
    print "</select></td><td>&#160;</td></tr>"

    print "<tr><td>Limit by AHRS ID: </td><td>"                            \
      "<select name=\"ahrs\" autocomplete=\"off\" style=\"width:100%;\">"                     \
      "<option value=\"\" selected=\"selected\"></option>"
    PROCINFO["sorted_in"] = "@ind_str_asc"
    for (i in AHRSList)
      print "<option value=\"" i "\">" i "</option>"
    print "</select></td><td>&#160;</td></tr>"
    
    print "<tr><td>Only with images: </td><td>"             \
      "<input type=\"checkbox\" name=\"img\" value=\"1\"/>"\
      "</td><td>&#160;</td></tr>"
    
    print "<tr><td>&#160;</td><td><input type=\"submit\" value=\"Submit\" style=\"width:100%;\"/></td><td>&#160;</td></tr>"
    print "</table>"
    #    print "<p>Search terms: plain text, or <a href=\"https://www.gnu.org/software/gawk/manual/gawk.html#Regexp\">regular expression</a>.<br/>Entering both Description and Material terms implies AND.</p><br/>"
    # print "<input type=\"submit\" value=\"Search\"/>"
    
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
    "rel=\"shortcut icon\" type=\"image/png\"/>"                        
  # print "<style type=\"text/css\">"                                     \
  #   "body { font-size: 14px; font-family: 'Montserrat', "               \
  #   "Verdana, Arial, Helvetica, sans-serif; }"                          \
  #   ".main {width: 1000px; padding-top: 10px; margin-left: auto;"       \
  #   "  margin-right: auto; }"                                           \
  #   "h1 { padding-top:20px; }"                                          \
  #   "select , option { font-size: 14px }"                               \
  #   "table { border-collapse: collapse }"                               \
  #   "td, th { border: 1px solid black; padding: 5px }"                  \
  #   "a { color:#15358d; text-decoration:none; border-bottom-style:none }" \
  #   "a:visited { color:#9f1dbc }"                                       \
  #   "a:hover {color:#15358d; border-bottom-style:solid; "               \
  #   "border-bottom-width:thin }"                                        \
  #   ".graph { max-width: 100%; }"                                       \
  #   "</style>"                                                        

  print "<link href=\"//fonts.googleapis.com/css?family=Raleway:400,300,600\" rel=\"stylesheet\" type=\"text/css\"/>"
  
  print "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"/>" \
    "<link rel=\"stylesheet\" href=\"css/normalize.css\"/>"             \
    "<link rel=\"stylesheet\" href=\"css/skeleton.css\"/>"              \
    "<link rel=\"stylesheet\" href=\"css/override.css\"/>"

  print "</head>\n<body>"
  #print "<div class=\"main\">"

  print "<div class=\"container\">"                 \
    "<div class=\"row\" style=\"margin-top: 5%\">"  \
    "<div class=\"eight columns\" >"

  # "<link href=\"https://fonts.googleapis.com/css?family=Montserrat\" " \
  #  "rel=\"stylesheet\"/>"                                              \

}

function footer() {
  print "</div><div class=\"four columns\">"
  print "<a class=\"button\" style=\"width:100%\" href=\"do\">Home</a><br/>"
  print "<p style=\"border: 1px solid #BBB; border-radius: 4px; padding: 20px; background-color: #dbffa3;\">The site of Wales, Alaska, on the coast of Bering Strait, exists at a crossroads of continents and provides a rich sequence of human activity for over 1200 years. Wales was the site of ten years of recent archaeological investigations, which produced approximately 30,000 artifacts, faunal and floral remains, and sediment samples.<br/><br/>This website offers access to the Wales collections the <a href=\"https://www.uaf.edu/museum/collections/archaeo/\">University of Alaska Museum of the North</a>. Website development funded by US NSF grant <a href=\"https://www.nsf.gov/awardsearch/showAward?AWD_ID=2040323\">2040323</a>.</p>"
  print "</div></div></div>"
  
  # print "</div>"
  print "</body>\n</html>";
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

function readdata(   m, mn) {
  
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
    if ($17) {
      mn = split($17, m ,",")
      for (i = 1; i<=mn; i++)
        Media[$1][i]   = m[i]
    }
    WhatList[$5]++
    MatList[$6]++
    SiteList[$3]++
    AHRSList[$2]++
  }
}
