import os, fnmatch, re
def findCount(directory):
    elementList = {}
    uQFElementList = {}
    mathMLElementList = {}
    entityList = {}
    wordTotal = 0
    for path, dirs, files in os.walk(os.path.abspath(directory)):
        for filename in files:
            if filename.lower().endswith(('wb.xml', 'bk.xml')):
                filepath = os.path.join(path, filename)
                with open(filepath, encoding='utf-8') as f:
                    s = f.read()
                regex = '<([A-Za-z0-9]+)[ >]'
                match = re.findall(regex,s)
                for i in match:
                    try:
                        elementList[i] += 1
                    except KeyError:
                        elementList[i] = 1
                regex = '<uqf:([A-Za-z0-9]+)[ >]'
                match = re.findall(regex,s)
                for i in match:
                    try:
                        uQFElementList[i] += 1
                    except KeyError:
                        uQFElementList[i] = 1
                regex = '<mml:([A-Za-z0-9]+)[ >]'
                match = re.findall(regex,s)
                for i in match:
                    try:
                        mathMLElementList[i] += 1
                    except KeyError:
                        mathMLElementList[i] = 1
                regex = '&([A-Za-z0-9]+);'
                match = re.findall(regex,s)
                for i in match:
                    try:
                        entityList[i] += 1
                    except KeyError:
                        entityList[i] = 1
    outfile = open('nonamespace-elements-as-xmlsetups.tex', 'w', encoding='utf-8')
    elementSortedKeys = sorted(elementList, key=elementList.get, reverse=True)
    for r in elementSortedKeys:
        outfile.write ('%')
        outfile.write (r.upper())
        outfile.write ('\n\\startxmlsetups xml:capdm:')
        outfile.write (r)
        outfile.write ('\n \\xmlflush{#1}\n\\stopxmlsetups\n\n')
    outfile.close()
    outfile = open('uqf-elements-as-xmlsetups.tex', 'w', encoding='utf-8')
    outfile.write ('\\startxmlsetups xml:capdm:uqfnamespace\n')
    elementSortedKeys = sorted(uQFElementList, key=uQFElementList.get, reverse=True)
    for r in elementSortedKeys:
        outfile.write (' \\xmlsetsetup{#1}{uqf:')
        outfile.write (r)
        outfile.write ('}{xml:capdm:uqf')
        outfile.write (r)
        outfile.write ('}\n')
    outfile.write ('\\stopxmlsetups\n\\xmlregisterdocumentsetup{capdm}{xml:capdm:uqfnamespace}\n\n')
    for r in elementSortedKeys:
        outfile.write ('%UQF')
        outfile.write (r.upper())
        outfile.write ('\n\\startxmlsetups xml:capdm:uqf')
        outfile.write (r)
        outfile.write ('\n \\xmlflush{#1}\n\\stopxmlsetups\n\n')
    outfile.close()
    outfile = open('mathml-elements-as-xmlsetups.tex', 'w', encoding='utf-8')
    outfile.write ('\\startxmlsetups xml:capdm:mathmlnamespace\n')
    elementSortedKeys = sorted(mathMLElementList, key=mathMLElementList.get, reverse=True)
    for r in elementSortedKeys:
        outfile.write (' \\xmlsetsetup{#1}{mml:')
        outfile.write (r)
        outfile.write ('}{xml:capdm:mml')
        outfile.write (r)
        outfile.write ('}\n')
    outfile.write ('\\stopxmlsetups\n\\xmlregisterdocumentsetup{capdm}{xml:capdm:mathmlnamespace}\n\n')
    for r in elementSortedKeys:
        outfile.write ('%MML')
        outfile.write (r.upper())
        outfile.write ('\n\\startxmlsetups xml:capdm:mml')
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
