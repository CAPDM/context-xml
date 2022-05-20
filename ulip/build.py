import os, fnmatch, re
def findCount(directory):
    elementList = {}
    entityList = {}
    wordTotal = 0
    for path, dirs, files in os.walk(os.path.abspath(directory)):
        for filename in files:
            if filename.lower().endswith(('wb.xml', 'bk.xml')):
                filepath = os.path.join(path, filename)
                with open(filepath, encoding='utf-8') as f:
                    s = f.read()
                regex = '<([a-z]+)[ >]'
                match = re.findall(regex,s)
                for i in match:
                    try:
                        elementList[i] += 1
                    except KeyError:
                        elementList[i] = 1
                regex = '&([a-z]+);'
                match = re.findall(regex,s)
                for i in match:
                    try:
                        entityList[i] += 1
                    except KeyError:
                        entityList[i] = 1
    outfile = open('all-elements-as-xmlsetups.tex', 'w', encoding='utf-8')
    elementSortedKeys = sorted(elementList, key=elementList.get, reverse=True)
    for r in elementSortedKeys:
        outfile.write ('%')
        outfile.write (r.upper())
        outfile.write ('\n\\startxmlsetups xml:capdm:')
        outfile.write (r)
        outfile.write ('\n \\xmlflush{#1}\n\\stopxmlsetups\n\n')
    outfile.close()
    outfile = open('all-entities-as-xmltexentity.tex', 'w', encoding='utf-8')
#    entitySortedKeys = sorted(entityList, key=entityList.get, reverse=True)
    for r in sorted(entityList):
        outfile.write ('\\xmltexentity{')
        outfile.write (r)
        outfile.write ('}{}\n')
    outfile.close()

findCount("C:/Work/svn/ULIP repo")
## findCount("C:/Work/svn/MPE text")
