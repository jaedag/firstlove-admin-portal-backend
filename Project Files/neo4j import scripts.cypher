// Q1 Town, Community and Centre data import script
//Delete all Entries
match (n)
detach delete n;

//Import Apostles data
LOAD CSV WITH HEADERS FROM "file:///Apostles.csv" as line
MERGE(m:Member{lastName:apoc.text.capitalizeAll(toLower(trim(line.`Last Name`)))})
	ON CREATE SET 
    m.memberID = apoc.create.uuid(),
    m.middleName = line.`Other Names`,
    m.firstName = apoc.text.capitalizeAll(toLower(trim(line.`FIRST NAME`))),
    m.phoneNumber = line.`Phone Number`,
    m.whatsappNumber = line.`WhatsApp Number (if different)`
    
MERGE(g: Gender {gender: apoc.text.capitalizeAll(toLower(trim(line.Gender)))})
MERGE(m)-[:HAS_GENDER]->(g)	

MERGE(ms: MaritalStatus {status: apoc.text.capitalizeAll(toLower(trim(line.`Marital Status`)))})
MERGE(m)-[:HAS_MARITAL_STATUS]->(ms);

LOAD CSV WITH HEADERS FROM "file:///Centres-Table%20Frank.csv" as line
MERGE(t:Town {name: apoc.text.capitalizeAll(toLower(trim(line.`TOWN`)))})
    ON CREATE SET 
	t.townID = apoc.create.uuid()

with line,t
MATCH (m: Member {lastName: line.`APOSTLE`})
MERGE (title: Title{title:'Apostle'})
MERGE (m)-[:HAS_TITLE]-> (title)
MERGE (t)<-[:HAS_TOWN]-(m)

with line WHERE line.COMMUNITY is not null
MERGE(C: Community {name: apoc.text.capitalizeAll(toLower(trim(line.COMMUNITY)))})
	ON CREATE SET
    C.communityID = apoc.create.uuid()

    with line, C
    MATCH (t: Town {name: apoc.text.capitalizeAll(toLower(trim(line.`TOWN`))) })
    MERGE(t)-[:HAS_COMMUNITY]->(C)

with line, C  WHERE line.`CENTRE NAME` is not null
MERGE(cen: Centre{name: apoc.text.capitalizeAll(toLower(trim(line.`CENTRE NAME`))),location: point({latitude:toFloat(line.LATITUDE), longitude:toFloat(line.LONGITUDE), crs:'WGS-84'})})
	ON CREATE SET 
    cen.centreID = apoc.create.uuid(),
    cen.centreCode = line.`SERVICE CODE`
MERGE (cen)<-[:HAS_CENTRE]-(C)
MERGE (l:Member {whatsappNumber: line.`PHONE NUMBER`})
MERGE (l)-[:LEADS_CENTRE]->(cen)

with line,cen
MERGE(sDay: ServiceDay {day: apoc.text.capitalizeAll(toLower(line.`SERVICE DAY`))} )
MERGE (sDay)<-[:MEETS_ON_DAY]-(cen);

 
// Q2 firstlove membership data Import script
LOAD CSV WITH HEADERS FROM "file:///Members.csv" as line
CREATE(m:Member {memberId: apoc.create.uuid()})
	SET 
    m.firstName = line.`First Name`,
    m.middleName = line.`Other Names`,
    m.lastName = line.`Last Name`,
    m.phoneNumber = line.`Phone Number`,
    m.whatsappNumber = line.`WhatsApp Number (if different)`,
    m.areaOfResidence = line.`Area of Residence`

with line,m
MERGE(g: Gender {gender: line.Gender})
MERGE(m)-[:HAS_GENDER]->(g)

with line,m
MATCH(ms: MaritalStatus {status: line.`Marital Status`})
MERGE(m)-[:HAS_MARITAL_STATUS]->(ms)

with line,m
MATCH(t:Town {name:  line.`Name of Campus/Town/SHS/Flow`})
MERGE (m)-[:BELONGS_TO_TOWN]->(t)

with line, m  WHERE line.`Ministry` is not null
MERGE(son: Sonta {name:line.`Ministry`})
MERGE(m)-[:BELONGS_TO_SONTA]->(son);

LOAD CSV WITH HEADERS FROM "file:///Members.csv" as line 
WITH line 
WHERE line.`Date of Birth`is not null
MATCH (m:Member {whatsappNumber: line.`WhatsApp Number (if different)`})
MERGE (dob: TimeGraph {date: date(line.`Date of Birth`)})
MERGE (m)-[:WAS_BORN_ON]->(dob);

LOAD CSV WITH HEADERS FROM "file:///Members.csv" as line 
WITH line 
WHERE line.Occupation is not null
MATCH (m:Member {whatsappNumber: line.`WhatsApp Number (if different)`})
MERGE(O:Occupation {occupation: line.Occupation})
MERGE(m)-[:HAS_OCCUPATION]->(O);

LOAD CSV WITH HEADERS FROM "file:///Members.csv" as line
WITH line 
WHERE line.`Attending Church or FLOW Church` is not null
MATCH (m:Member {whatsappNumber: line.`WhatsApp Number (if different)`})
MERGE(f:FlowChurch {name: line.`Attending Church or FLOW Church`})
MERGE (m)-[:BELONGS_TO_FLOWCHURCH]->(f)
MERGE (a:Apostle {firstName:'Frank',lastName:'Opoku'})
MERGE (f)<-[:HAS_FLOW_CHURCH]-(a);

LOAD CSV WITH HEADERS FROM "file:///Communities.csv" as line
MERGE (m:Member {whatsappNumber: line.`Whatsapp Number`})

with line,m
MATCH (com: Community {name: line.Community})
MERGE (m)-[:LEADS_COMMUNITY]->(com)
RETURN m,com;

LOAD CSV WITH HEADERS FROM "file:///Town.csv" as line WITH line WHERE line.`Whatsapp Number` IS NOT NULL
MERGE (m:Member {whatsappNumber: line.`Whatsapp Number`})

with line,m
MERGE (t:Town {name:apoc.text.capitalizeAll(toLower(trim(line.`Town`)))})
MERGE (m)-[:LEADS_TOWN]->(t)
RETURN m,t;

//Q3 Sonta Relationships
LOAD CSV WITH HEADERS FROM "file:///Sonta.csv" as line
MERGE (m:Member {whatsappNumber: line.`WhatsApp Number`})

with line,m
MERGE (sonta: Sonta {name: line.Sonta})
MERGE (m)-[:LEADS_SONTA]->(sonta)

with line, m,sonta
MATCH (t: Town {name: line.Town})
MERGE (t)-[:HAS_SONTA]->(sonta)
RETURN m;

// Load Data for Campus Centres, Halls 
LOAD CSV WITH HEADERS FROM "file:///Centres-Table%20Campus.csv" as line
MERGE(camp:Campus {name: apoc.text.capitalizeAll(toLower(trim(line.`CAMPUS`)))})
    ON CREATE SET 
	camp.campusID = apoc.create.uuid()

with line,camp
MATCH (m: Member {lastName: line.`APOSTLE`})
MERGE (title: Title {title:'Apostle'})
// MERGE (apostleship:Apostleship {name:line.Apostleship})
MERGE (m)-[:HAS_TITLE]-> (title)
MERGE (camp)<-[:HAS_CAMPUS]-(m)
// MERGE (m)-[:LEADS_APOSTLESHIP]->(apostleship)

with line WHERE line.HALL is not null
MERGE(hall: Hall {name: apoc.text.capitalizeAll(toLower(trim(line.HALL)))})
	ON CREATE SET
    hall.hallID = apoc.create.uuid()

    with line, hall
    MATCH (camp: Campus {name: apoc.text.capitalizeAll(toLower(trim(line.`CAMPUS`))) })
    MERGE(camp)-[:HAS_HALL]->(hall)

with line, hall  WHERE line.`CENTRE NAME` is not null
MERGE(cen: Centre{name: apoc.text.capitalizeAll(toLower(trim(line.`CENTRE NAME`))),location: point({latitude:toFloat(line.LATITUDE), longitude:toFloat(line.LONGITUDE), crs:'WGS-84'})})
	ON CREATE SET 
    cen.centreID = apoc.create.uuid(),
    cen.centreCode = line.`SERVICE CODE`
MERGE (cen)<-[:HAS_CENTRE]-(hall)
MERGE (l:Member {whatsappNumber: line.`PHONE NUMBER`})
MERGE (l)-[:LEADS_CENTRE]->(cen)

with line,cen
MERGE(sDay: ServiceDay {day: apoc.text.capitalizeAll(toLower(line.`SERVICE DAY`))} )
MERGE (sDay)<-[:MEETS_ON_DAY]-(cen);

LOAD CSV WITH HEADERS FROM "file:///Halls.csv" as line
MERGE (m:Member {whatsappNumber: line.`Whatsapp Number`})

with line,m
MATCH (hall: Hall {name: line.Hall})
MERGE (m)-[:LEADS_HALL]->(hall)
RETURN m,hall;