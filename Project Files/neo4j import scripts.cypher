// Q1 Town, Community and Centre data import script
//Delete all Entries
match (n)
detach delete n;

//Import Apostles data
LOAD CSV WITH HEADERS FROM "file:///Apostles.csv" as line
MERGE(m:Member{lastName:line.`Last Name`})
	ON CREATE SET 
    m.memberID = apoc.create.uuid(),
    m.middleName = line.`Other Names`,
    m.firstName = line.`FIRST NAME`,
    m.phoneNumber = line.`Phone Number`,
    m.whatsappNumber = line.`WhatsApp Number (if different)`
    
MERGE(g: Gender {gender: line.Gender})
MERGE(m)-[:HAS_GENDER]->(g)	

MERGE(ms: MaritalStatus {status: line.`Marital Status`})
MERGE(m)-[:HAS_MARITAL_STATUS]->(ms);

LOAD CSV WITH HEADERS FROM "file:///Centres-Table.csv" as line
MERGE(t:Town {name: apoc.text.capitalizeAll(toLower(trim(line.`TOWN`)))})
    ON CREATE SET 
	t.townID = apoc.create.uuid()
with line,t
MATCH (m: Member {whatsappNumber: line.`APOSTLE`})
MERGE (l: Leader{rank:'Apostle', title:'Apostle'})
MERGE (apostleship:Apostleship {name:'Frank Opoku'})
MERGE (t)<-[:HAS_TOWN]-(apostleship)
MERGE (m)-[:IS_LEADER]->(l)
MERGE (l)-[:LEADS]->(apostleship)

with line, m  WHERE line.COMMUNITY is not null
MERGE(C: Community {name: apoc.text.capitalizeAll(toLower(trim(line.COMMUNITY)))})
	ON CREATE SET
    C.communityID = apoc.create.uuid()

    with line, m, C
    MATCH (t: Town {name: apoc.text.capitalizeAll(toLower(trim(line.`TOWN`))) })
    MERGE(t)-[:HAS_COMMUNITY]->(C)

with line, m, C  WHERE line.`CENTRE NAME` is not null
MERGE(cen: Centre{name: apoc.text.capitalizeAll(toLower(trim(line.`CENTRE NAME`))),location: point({latitude:toFloat(line.LATITUDE), longitude:toFloat(line.LONGITUDE), crs:'WGS-84'})})
	ON CREATE SET 
    cen.centreID = apoc.create.uuid(),
    cen.centreCode = line.`SERVICE CODE`
 	// cen.location =  point({latitude:toFloat(line.LATITUDE), longitude:toFloat(line.LONGITUDE), crs:'WGS-84'})
    // MERGE (cen { location: point({latitude:toFloat(line.LATITUDE), longitude:toFloat(line.LONGITUDE), crs:'WGS-84'})})
MERGE (cen)<-[:HAS_CENTRE]-(C)

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
    m.residenceArea = line.`Area of Residence`

with line,m
MERGE(g: Gender {gender: line.Gender})
MERGE(m)-[:HAS_GENDER]->(g)

with line,m
MATCH(ms: MaritalStatus {status: line.`Marital Status`})
MERGE(m)-[:HAS_MARITAL_STATUS]->(ms)

with line,m
MATCH(t:Town {name:  line.`Name of Campus/Town/SHS/Flow`})
MERGE (m)-[:BELONGS_TO_TOWN]->(t)

with line,m
MERGE(f:FlowChurch {name: line.`Attending Church or FLOW Church`})
MERGE (m)-[:BELONGS_TO_FLOW]->(f)
MERGE (apostleship:Apostleship {name:'Frank Opoku'})
MERGE (f)<-[:HAS_FLOW_CHURCH]-(apostleship)

with line, m  WHERE line.`Ministry` is not null
MERGE(son: Sonta {name:line.`Ministry`})
MERGE(m)-[:BELONGS_TO_MINISTRY]->(son)

with line,m WHERE line.`Date of Birth`is not null
MERGE(d: DateofBirth{date: datetime(line.`Date of Birth`)})
MERGE(m)-[:WAS_BORN_ON]->(d)

with line,m WHERE line.occupation is not null
MERGE(O:Occupation {occupation: line.occupation})
MERGE(m)-[:HAS_OCCUPATION]->(O);

LOAD CSV WITH HEADERS FROM "file:///Communities.csv" as line
MERGE (m:Member {whatsappNumber: line.`Whatsapp Number`})
MERGE (l: Leader {rank: 'Community Leader'})
MERGE (m)-[:IS_LEADER]->(l)

with line,l,m
MATCH (t: Town {name: line.Town})
MERGE (l)-[:LEADS]->(com)
RETURN m,l,com;

LOAD CSV WITH HEADERS FROM "file:///Town.csv" as line WITH line WHERE line.`Whatsapp Number` IS NOT NULL
MERGE (m:Member {whatsappNumber: line.`Whatsapp Number`})
MERGE (l: Leader {rank: 'GSO'})
MERGE (m)-[:IS_LEADER]->(l)

with line,l,m
MERGE (t:Town {name:apoc.text.capitalizeAll(toLower(trim(line.`Town`)))})
CREATE (l)-[:LEADS]->(t)
RETURN m,l,t;

//Q3 Sonta Relationships

LOAD CSV WITH HEADERS FROM "file:///Sonta.csv" as line
MERGE (m:Member {whatsappNumber: line.`WhatsApp Number`})
MERGE (l: Leader {rank: 'Sonta Leader'})
MERGE (m)-[:IS_LEADER]->(l)

with line,l,m
MERGE (sonta: Sonta {name: line.Sonta})
MERGE (l)-[:LEADS]->(sonta)

with line, l,m,sonta
MATCH (t: Town {name: line.Town})
MERGE (t)-[:HAS_SONTA]->(sonta)
RETURN m;
