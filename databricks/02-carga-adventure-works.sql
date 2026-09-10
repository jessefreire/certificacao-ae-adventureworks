-- Carga do AdventureWorks no Databricks
-- 65 tabelas. Cast explicito por posicao (_c0.._cN) porque o TSV
-- nao tem cabecalho. O caminho ja aponta para o volume real; se os arquivos
-- estiverem em outro lugar, o script e regerado a partir de uma variavel.
--
-- nullValue = '' e obrigatorio: sem ele, coluna int com campo vazio recebe
-- 0 em vez de NULL. So no salesorderheader sao 27.659 pedidos sem vendedor.
--
-- Se voce subir os arquivos para outro caminho, avise: o script e regerado,
-- e melhor do que ajustar 65 caminhos a mao.

-- Nome em tres niveis de proposito: nao depende do catalogo selecionado no
-- editor. O `use catalog` faria o mesmo, mas quebra o parser do sqlfluff 1.4.5.

-- Person.BusinessEntity: 3 colunas
copy into workspace.adventure_works.businessentity
from (
    select
        cast(_c0 as int) as businessentityid
        , cast(_c1 as string) as rowguid
        , cast(_c2 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/BusinessEntity.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Person.Person: 13 colunas
copy into workspace.adventure_works.person
from (
    select
        cast(_c0 as int) as businessentityid
        , cast(_c1 as string) as persontype
        , cast(_c2 as boolean) as namestyle
        , cast(_c3 as string) as title
        , cast(_c4 as string) as firstname
        , cast(_c5 as string) as middlename
        , cast(_c6 as string) as lastname
        , cast(_c7 as string) as suffix
        , cast(_c8 as int) as emailpromotion
        , cast(_c9 as string) as additionalcontactinfo
        , cast(_c10 as string) as demographics
        , cast(_c11 as string) as rowguid
        , cast(_c12 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Person.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Person.StateProvince: 8 colunas
copy into workspace.adventure_works.stateprovince
from (
    select
        cast(_c0 as int) as stateprovinceid
        , cast(_c1 as string) as stateprovincecode
        , cast(_c2 as string) as countryregioncode
        , cast(_c3 as boolean) as isonlystateprovinceflag
        , cast(_c4 as string) as name
        , cast(_c5 as int) as territoryid
        , cast(_c6 as string) as rowguid
        , cast(_c7 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/StateProvince.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Person.Address: 9 colunas
copy into workspace.adventure_works.address
from (
    select
        cast(_c0 as int) as addressid
        , cast(_c1 as string) as addressline1
        , cast(_c2 as string) as addressline2
        , cast(_c3 as string) as city
        , cast(_c4 as int) as stateprovinceid
        , cast(_c5 as string) as postalcode
        , cast(_c6 as string) as spatiallocation
        , cast(_c7 as string) as rowguid
        , cast(_c8 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Address.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Person.AddressType: 4 colunas
copy into workspace.adventure_works.addresstype
from (
    select
        cast(_c0 as int) as addresstypeid
        , cast(_c1 as string) as name
        , cast(_c2 as string) as rowguid
        , cast(_c3 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/AddressType.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Person.BusinessEntityAddress: 5 colunas
copy into workspace.adventure_works.businessentityaddress
from (
    select
        cast(_c0 as int) as businessentityid
        , cast(_c1 as int) as addressid
        , cast(_c2 as int) as addresstypeid
        , cast(_c3 as string) as rowguid
        , cast(_c4 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/BusinessEntityAddress.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Person.ContactType: 3 colunas
copy into workspace.adventure_works.contacttype
from (
    select
        cast(_c0 as int) as contacttypeid
        , cast(_c1 as string) as name
        , cast(_c2 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ContactType.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Person.BusinessEntityContact: 5 colunas
copy into workspace.adventure_works.businessentitycontact
from (
    select
        cast(_c0 as int) as businessentityid
        , cast(_c1 as int) as personid
        , cast(_c2 as int) as contacttypeid
        , cast(_c3 as string) as rowguid
        , cast(_c4 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/BusinessEntityContact.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Person.EmailAddress: 5 colunas
copy into workspace.adventure_works.emailaddress
from (
    select
        cast(_c0 as int) as businessentityid
        , cast(_c1 as int) as emailaddressid
        , cast(_c2 as string) as emailaddress
        , cast(_c3 as string) as rowguid
        , cast(_c4 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/EmailAddress.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Person.Password: 5 colunas
copy into workspace.adventure_works.password
from (
    select
        cast(_c0 as int) as businessentityid
        , cast(_c1 as string) as passwordhash
        , cast(_c2 as string) as passwordsalt
        , cast(_c3 as string) as rowguid
        , cast(_c4 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Password.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Person.PhoneNumberType: 3 colunas
copy into workspace.adventure_works.phonenumbertype
from (
    select
        cast(_c0 as int) as phonenumbertypeid
        , cast(_c1 as string) as name
        , cast(_c2 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/PhoneNumberType.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Person.PersonPhone: 4 colunas
copy into workspace.adventure_works.personphone
from (
    select
        cast(_c0 as int) as businessentityid
        , cast(_c1 as string) as phonenumber
        , cast(_c2 as int) as phonenumbertypeid
        , cast(_c3 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/PersonPhone.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Person.CountryRegion: 3 colunas
copy into workspace.adventure_works.countryregion
from (
    select
        cast(_c0 as string) as countryregioncode
        , cast(_c1 as string) as name
        , cast(_c2 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/CountryRegion.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- HumanResources.Department: 4 colunas
copy into workspace.adventure_works.department
from (
    select
        cast(_c0 as int) as departmentid
        , cast(_c1 as string) as name
        , cast(_c2 as string) as groupname
        , cast(_c3 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Department.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- HumanResources.Employee: 16 colunas
copy into workspace.adventure_works.employee
from (
    select
        cast(_c0 as int) as businessentityid
        , cast(_c1 as string) as nationalidnumber
        , cast(_c2 as string) as loginid
        , cast(_c3 as string) as org
        , cast(_c4 as int) as organizationlevel
        , cast(_c5 as string) as jobtitle
        , cast(_c6 as timestamp) as birthdate
        , cast(_c7 as string) as maritalstatus
        , cast(_c8 as string) as gender
        , cast(_c9 as timestamp) as hiredate
        , cast(_c10 as boolean) as salariedflag
        , cast(_c11 as smallint) as vacationhours
        , cast(_c12 as smallint) as sickleavehours
        , cast(_c13 as boolean) as currentflag
        , cast(_c14 as string) as rowguid
        , cast(_c15 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Employee.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- HumanResources.EmployeeDepartmentHistory: 6 colunas
copy into workspace.adventure_works.employeedepartmenthistory
from (
    select
        cast(_c0 as int) as businessentityid
        , cast(_c1 as smallint) as departmentid
        , cast(_c2 as smallint) as shiftid
        , cast(_c3 as timestamp) as startdate
        , cast(_c4 as timestamp) as enddate
        , cast(_c5 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/EmployeeDepartmentHistory.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- HumanResources.EmployeePayHistory: 5 colunas
copy into workspace.adventure_works.employeepayhistory
from (
    select
        cast(_c0 as int) as businessentityid
        , cast(_c1 as timestamp) as ratechangedate
        , cast(_c2 as decimal(19, 4)) as rate
        , cast(_c3 as smallint) as payfrequency
        , cast(_c4 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/EmployeePayHistory.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- HumanResources.JobCandidate: 4 colunas
copy into workspace.adventure_works.jobcandidate
from (
    select
        cast(_c0 as int) as jobcandidateid
        , cast(_c1 as int) as businessentityid
        , cast(_c2 as string) as resume
        , cast(_c3 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/JobCandidate.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- HumanResources.Shift: 5 colunas
copy into workspace.adventure_works.shift
from (
    select
        cast(_c0 as int) as shiftid
        , cast(_c1 as string) as name
        , cast(_c2 as string) as starttime
        , cast(_c3 as string) as endtime
        , cast(_c4 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Shift.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Production.BillOfMaterials: 9 colunas
copy into workspace.adventure_works.billofmaterials
from (
    select
        cast(_c0 as int) as billofmaterialsid
        , cast(_c1 as int) as productassemblyid
        , cast(_c2 as int) as componentid
        , cast(_c3 as timestamp) as startdate
        , cast(_c4 as timestamp) as enddate
        , cast(_c5 as decimal(19, 4)) as unitmeasurecode
        , cast(_c6 as smallint) as bomlevel
        , cast(_c7 as string) as perassemblyqty
        , cast(_c8 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/BillOfMaterials.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Production.Culture: 3 colunas
copy into workspace.adventure_works.culture
from (
    select
        cast(_c0 as string) as cultureid
        , cast(_c1 as string) as name
        , cast(_c2 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Culture.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Production.ProductCategory: 4 colunas
copy into workspace.adventure_works.productcategory
from (
    select
        cast(_c0 as int) as productcategoryid
        , cast(_c1 as string) as name
        , cast(_c2 as string) as rowguid
        , cast(_c3 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductCategory.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Production.ProductSubcategory: 5 colunas
copy into workspace.adventure_works.productsubcategory
from (
    select
        cast(_c0 as int) as productsubcategoryid
        , cast(_c1 as int) as productcategoryid
        , cast(_c2 as string) as name
        , cast(_c3 as string) as rowguid
        , cast(_c4 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductSubcategory.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Production.ProductModel: 6 colunas
copy into workspace.adventure_works.productmodel
from (
    select
        cast(_c0 as int) as productmodelid
        , cast(_c1 as string) as name
        , cast(_c2 as string) as catalogdescription
        , cast(_c3 as string) as instructions
        , cast(_c4 as string) as rowguid
        , cast(_c5 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductModel.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Production.Product: 25 colunas
copy into workspace.adventure_works.product
from (
    select
        cast(_c0 as int) as productid
        , cast(_c1 as string) as name
        , cast(_c2 as string) as productnumber
        , cast(_c3 as boolean) as makeflag
        , cast(_c4 as boolean) as finishedgoodsflag
        , cast(_c5 as string) as color
        , cast(_c6 as smallint) as safetystocklevel
        , cast(_c7 as smallint) as reorderpoint
        , cast(_c8 as decimal(19, 4)) as standardcost
        , cast(_c9 as decimal(19, 4)) as listprice
        , cast(_c10 as string) as size
        , cast(_c11 as string) as sizeunitmeasurecode
        , cast(_c12 as string) as weightunitmeasurecode
        , cast(_c13 as decimal(19, 4)) as weight
        , cast(_c14 as int) as daystomanufacture
        , cast(_c15 as string) as productline
        , cast(_c16 as string) as class
        , cast(_c17 as string) as style
        , cast(_c18 as int) as productsubcategoryid
        , cast(_c19 as int) as productmodelid
        , cast(_c20 as timestamp) as sellstartdate
        , cast(_c21 as timestamp) as sellenddate
        , cast(_c22 as timestamp) as discontinueddate
        , cast(_c23 as string) as rowguid
        , cast(_c24 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Product.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Production.ProductCostHistory: 5 colunas
copy into workspace.adventure_works.productcosthistory
from (
    select
        cast(_c0 as int) as productid
        , cast(_c1 as timestamp) as startdate
        , cast(_c2 as timestamp) as enddate
        , cast(_c3 as decimal(19, 4)) as standardcost
        , cast(_c4 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductCostHistory.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Production.ProductDescription: 4 colunas
copy into workspace.adventure_works.productdescription
from (
    select
        cast(_c0 as int) as productdescriptionid
        , cast(_c1 as string) as description
        , cast(_c2 as string) as rowguid
        , cast(_c3 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductDescription.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Production.ProductDocument: 3 colunas
copy into workspace.adventure_works.productdocument
from (
    select
        cast(_c0 as int) as productid
        , cast(_c1 as string) as doc
        , cast(_c2 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductDocument.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Production.Location: 5 colunas
copy into workspace.adventure_works.location
from (
    select
        cast(_c0 as int) as locationid
        , cast(_c1 as string) as name
        , cast(_c2 as decimal(19, 4)) as costrate
        , cast(_c3 as string) as availability
        , cast(_c4 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Location.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Production.ProductInventory: 7 colunas
copy into workspace.adventure_works.productinventory
from (
    select
        cast(_c0 as int) as productid
        , cast(_c1 as smallint) as locationid
        , cast(_c2 as string) as shelf
        , cast(_c3 as smallint) as bin
        , cast(_c4 as smallint) as quantity
        , cast(_c5 as string) as rowguid
        , cast(_c6 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductInventory.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Production.ProductListPriceHistory: 5 colunas
copy into workspace.adventure_works.productlistpricehistory
from (
    select
        cast(_c0 as int) as productid
        , cast(_c1 as timestamp) as startdate
        , cast(_c2 as timestamp) as enddate
        , cast(_c3 as decimal(19, 4)) as listprice
        , cast(_c4 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductListPriceHistory.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Production.Illustration: 3 colunas
copy into workspace.adventure_works.illustration
from (
    select
        cast(_c0 as int) as illustrationid
        , cast(_c1 as string) as diagram
        , cast(_c2 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Illustration.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Production.ProductModelIllustration: 3 colunas
copy into workspace.adventure_works.productmodelillustration
from (
    select
        cast(_c0 as int) as productmodelid
        , cast(_c1 as int) as illustrationid
        , cast(_c2 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductModelIllustration.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Production.ProductModelProductDescriptionCulture: 4 colunas
copy into workspace.adventure_works.productmodelproductdescriptionculture
from (
    select
        cast(_c0 as int) as productmodelid
        , cast(_c1 as int) as productdescriptionid
        , cast(_c2 as string) as cultureid
        , cast(_c3 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductModelProductDescriptionCulture.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Production.ProductProductPhoto: 4 colunas
copy into workspace.adventure_works.productproductphoto
from (
    select
        cast(_c0 as int) as productid
        , cast(_c1 as int) as productphotoid
        , cast(_c2 as boolean) as `primary`
        , cast(_c3 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductProductPhoto.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Production.ScrapReason: 3 colunas
copy into workspace.adventure_works.scrapreason
from (
    select
        cast(_c0 as int) as scrapreasonid
        , cast(_c1 as string) as name
        , cast(_c2 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ScrapReason.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Production.TransactionHistory: 9 colunas
copy into workspace.adventure_works.transactionhistory
from (
    select
        cast(_c0 as int) as transactionid
        , cast(_c1 as int) as productid
        , cast(_c2 as int) as referenceorderid
        , cast(_c3 as int) as referenceorderlineid
        , cast(_c4 as timestamp) as transactiondate
        , cast(_c5 as string) as transactiontype
        , cast(_c6 as int) as quantity
        , cast(_c7 as decimal(19, 4)) as actualcost
        , cast(_c8 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/TransactionHistory.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Production.TransactionHistoryArchive: 9 colunas
copy into workspace.adventure_works.transactionhistoryarchive
from (
    select
        cast(_c0 as int) as transactionid
        , cast(_c1 as int) as productid
        , cast(_c2 as int) as referenceorderid
        , cast(_c3 as int) as referenceorderlineid
        , cast(_c4 as timestamp) as transactiondate
        , cast(_c5 as string) as transactiontype
        , cast(_c6 as int) as quantity
        , cast(_c7 as decimal(19, 4)) as actualcost
        , cast(_c8 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/TransactionHistoryArchive.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Production.UnitMeasure: 3 colunas
copy into workspace.adventure_works.unitmeasure
from (
    select
        cast(_c0 as decimal(19, 4)) as unitmeasurecode
        , cast(_c1 as string) as name
        , cast(_c2 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/UnitMeasure.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Production.WorkOrder: 10 colunas
copy into workspace.adventure_works.workorder
from (
    select
        cast(_c0 as int) as workorderid
        , cast(_c1 as int) as productid
        , cast(_c2 as int) as orderqty
        , cast(_c3 as int) as stockedqty
        , cast(_c4 as smallint) as scrappedqty
        , cast(_c5 as timestamp) as startdate
        , cast(_c6 as timestamp) as enddate
        , cast(_c7 as timestamp) as duedate
        , cast(_c8 as smallint) as scrapreasonid
        , cast(_c9 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/WorkOrder.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Production.WorkOrderRouting: 12 colunas
copy into workspace.adventure_works.workorderrouting
from (
    select
        cast(_c0 as int) as workorderid
        , cast(_c1 as int) as productid
        , cast(_c2 as smallint) as operationsequence
        , cast(_c3 as smallint) as locationid
        , cast(_c4 as timestamp) as scheduledstartdate
        , cast(_c5 as timestamp) as scheduledenddate
        , cast(_c6 as timestamp) as actualstartdate
        , cast(_c7 as timestamp) as actualenddate
        , cast(_c8 as string) as actualresourcehrs
        , cast(_c9 as decimal(19, 4)) as plannedcost
        , cast(_c10 as decimal(19, 4)) as actualcost
        , cast(_c11 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/WorkOrderRouting.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Purchasing.ProductVendor: 11 colunas
copy into workspace.adventure_works.productvendor
from (
    select
        cast(_c0 as int) as productid
        , cast(_c1 as int) as businessentityid
        , cast(_c2 as decimal(19, 4)) as averageleadtime
        , cast(_c3 as decimal(19, 4)) as standardprice
        , cast(_c4 as decimal(19, 4)) as lastreceiptcost
        , cast(_c5 as timestamp) as lastreceiptdate
        , cast(_c6 as decimal(19, 4)) as minorderqty
        , cast(_c7 as decimal(19, 4)) as maxorderqty
        , cast(_c8 as decimal(19, 4)) as onorderqty
        , cast(_c9 as decimal(19, 4)) as unitmeasurecode
        , cast(_c10 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductVendor.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Purchasing.PurchaseOrderDetail: 11 colunas
copy into workspace.adventure_works.purchaseorderdetail
from (
    select
        cast(_c0 as int) as purchaseorderid
        , cast(_c1 as int) as purchaseorderdetailid
        , cast(_c2 as timestamp) as duedate
        , cast(_c3 as smallint) as orderqty
        , cast(_c4 as int) as productid
        , cast(_c5 as decimal(19, 4)) as unitprice
        , cast(_c6 as decimal(19, 4)) as linetotal
        , cast(_c7 as string) as receivedqty
        , cast(_c8 as string) as rejectedqty
        , cast(_c9 as decimal(19, 4)) as stockedqty
        , cast(_c10 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/PurchaseOrderDetail.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Purchasing.PurchaseOrderHeader: 13 colunas
copy into workspace.adventure_works.purchaseorderheader
from (
    select
        cast(_c0 as int) as purchaseorderid
        , cast(_c1 as smallint) as revisionnumber
        , cast(_c2 as smallint) as status
        , cast(_c3 as int) as employeeid
        , cast(_c4 as int) as vendorid
        , cast(_c5 as int) as shipmethodid
        , cast(_c6 as timestamp) as orderdate
        , cast(_c7 as timestamp) as shipdate
        , cast(_c8 as decimal(19, 4)) as subtotal
        , cast(_c9 as decimal(19, 4)) as taxamt
        , cast(_c10 as decimal(19, 4)) as freight
        , cast(_c11 as decimal(19, 4)) as totaldue
        , cast(_c12 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/PurchaseOrderHeader.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Purchasing.ShipMethod: 6 colunas
copy into workspace.adventure_works.shipmethod
from (
    select
        cast(_c0 as int) as shipmethodid
        , cast(_c1 as string) as name
        , cast(_c2 as decimal(19, 4)) as shipbase
        , cast(_c3 as decimal(19, 4)) as shiprate
        , cast(_c4 as string) as rowguid
        , cast(_c5 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ShipMethod.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Purchasing.Vendor: 8 colunas
copy into workspace.adventure_works.vendor
from (
    select
        cast(_c0 as int) as businessentityid
        , cast(_c1 as string) as accountnumber
        , cast(_c2 as string) as name
        , cast(_c3 as smallint) as creditrating
        , cast(_c4 as boolean) as preferredvendorstatus
        , cast(_c5 as boolean) as activeflag
        , cast(_c6 as string) as purchasingwebserviceurl
        , cast(_c7 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Vendor.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.CountryRegionCurrency: 3 colunas
copy into workspace.adventure_works.countryregioncurrency
from (
    select
        cast(_c0 as string) as countryregioncode
        , cast(_c1 as string) as currencycode
        , cast(_c2 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/CountryRegionCurrency.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.CreditCard: 6 colunas
copy into workspace.adventure_works.creditcard
from (
    select
        cast(_c0 as int) as creditcardid
        , cast(_c1 as string) as cardtype
        , cast(_c2 as string) as cardnumber
        , cast(_c3 as smallint) as expmonth
        , cast(_c4 as smallint) as expyear
        , cast(_c5 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/CreditCard.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.Currency: 3 colunas
copy into workspace.adventure_works.currency
from (
    select
        cast(_c0 as string) as currencycode
        , cast(_c1 as string) as name
        , cast(_c2 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Currency.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.CurrencyRate: 7 colunas
copy into workspace.adventure_works.currencyrate
from (
    select
        cast(_c0 as int) as currencyrateid
        , cast(_c1 as timestamp) as currencyratedate
        , cast(_c2 as string) as fromcurrencycode
        , cast(_c3 as string) as tocurrencycode
        , cast(_c4 as decimal(19, 4)) as averagerate
        , cast(_c5 as decimal(19, 4)) as endofdayrate
        , cast(_c6 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/CurrencyRate.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.Customer: 7 colunas
copy into workspace.adventure_works.customer
from (
    select
        cast(_c0 as int) as customerid
        , cast(_c1 as int) as personid
        , cast(_c2 as int) as storeid
        , cast(_c3 as int) as territoryid
        , cast(_c4 as string) as accountnumber
        , cast(_c5 as string) as rowguid
        , cast(_c6 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Customer.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.PersonCreditCard: 3 colunas
copy into workspace.adventure_works.personcreditcard
from (
    select
        cast(_c0 as int) as businessentityid
        , cast(_c1 as int) as creditcardid
        , cast(_c2 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/PersonCreditCard.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.SalesOrderDetail: 11 colunas
copy into workspace.adventure_works.salesorderdetail
from (
    select
        cast(_c0 as int) as salesorderid
        , cast(_c1 as int) as salesorderdetailid
        , cast(_c2 as string) as carriertrackingnumber
        , cast(_c3 as smallint) as orderqty
        , cast(_c4 as int) as productid
        , cast(_c5 as int) as specialofferid
        , cast(_c6 as decimal(19, 4)) as unitprice
        , cast(_c7 as decimal(19, 4)) as unitpricediscount
        , cast(_c8 as decimal(19, 4)) as linetotal
        , cast(_c9 as string) as rowguid
        , cast(_c10 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesOrderDetail.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.SalesOrderHeader: 26 colunas
copy into workspace.adventure_works.salesorderheader
from (
    select
        cast(_c0 as int) as salesorderid
        , cast(_c1 as smallint) as revisionnumber
        , cast(_c2 as timestamp) as orderdate
        , cast(_c3 as timestamp) as duedate
        , cast(_c4 as timestamp) as shipdate
        , cast(_c5 as smallint) as status
        , cast(_c6 as boolean) as onlineorderflag
        , cast(_c7 as string) as salesordernumber
        , cast(_c8 as string) as purchaseordernumber
        , cast(_c9 as string) as accountnumber
        , cast(_c10 as int) as customerid
        , cast(_c11 as int) as salespersonid
        , cast(_c12 as int) as territoryid
        , cast(_c13 as int) as billtoaddressid
        , cast(_c14 as int) as shiptoaddressid
        , cast(_c15 as int) as shipmethodid
        , cast(_c16 as int) as creditcardid
        , cast(_c17 as string) as creditcardapprovalcode
        , cast(_c18 as int) as currencyrateid
        , cast(_c19 as decimal(19, 4)) as subtotal
        , cast(_c20 as decimal(19, 4)) as taxamt
        , cast(_c21 as decimal(19, 4)) as freight
        , cast(_c22 as decimal(19, 4)) as totaldue
        , cast(_c23 as string) as comment
        , cast(_c24 as string) as rowguid
        , cast(_c25 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesOrderHeader.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.SalesOrderHeaderSalesReason: 3 colunas
copy into workspace.adventure_works.salesorderheadersalesreason
from (
    select
        cast(_c0 as int) as salesorderid
        , cast(_c1 as int) as salesreasonid
        , cast(_c2 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesOrderHeaderSalesReason.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.SalesPerson: 9 colunas
copy into workspace.adventure_works.salesperson
from (
    select
        cast(_c0 as int) as businessentityid
        , cast(_c1 as int) as territoryid
        , cast(_c2 as decimal(19, 4)) as salesquota
        , cast(_c3 as decimal(19, 4)) as bonus
        , cast(_c4 as decimal(19, 4)) as commissionpct
        , cast(_c5 as decimal(19, 4)) as salesytd
        , cast(_c6 as decimal(19, 4)) as saleslastyear
        , cast(_c7 as string) as rowguid
        , cast(_c8 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesPerson.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.SalesPersonQuotaHistory: 5 colunas
copy into workspace.adventure_works.salespersonquotahistory
from (
    select
        cast(_c0 as int) as businessentityid
        , cast(_c1 as timestamp) as quotadate
        , cast(_c2 as decimal(19, 4)) as salesquota
        , cast(_c3 as string) as rowguid
        , cast(_c4 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesPersonQuotaHistory.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.SalesReason: 4 colunas
copy into workspace.adventure_works.salesreason
from (
    select
        cast(_c0 as int) as salesreasonid
        , cast(_c1 as string) as name
        , cast(_c2 as string) as reasontype
        , cast(_c3 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesReason.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.SalesTaxRate: 7 colunas
copy into workspace.adventure_works.salestaxrate
from (
    select
        cast(_c0 as int) as salestaxrateid
        , cast(_c1 as int) as stateprovinceid
        , cast(_c2 as smallint) as taxtype
        , cast(_c3 as decimal(19, 4)) as taxrate
        , cast(_c4 as string) as name
        , cast(_c5 as string) as rowguid
        , cast(_c6 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesTaxRate.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.SalesTerritory: 10 colunas
copy into workspace.adventure_works.salesterritory
from (
    select
        cast(_c0 as int) as territoryid
        , cast(_c1 as string) as name
        , cast(_c2 as string) as countryregioncode
        , cast(_c3 as string) as `group`
        , cast(_c4 as decimal(19, 4)) as salesytd
        , cast(_c5 as decimal(19, 4)) as saleslastyear
        , cast(_c6 as decimal(19, 4)) as costytd
        , cast(_c7 as decimal(19, 4)) as costlastyear
        , cast(_c8 as string) as rowguid
        , cast(_c9 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesTerritory.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.SalesTerritoryHistory: 6 colunas
copy into workspace.adventure_works.salesterritoryhistory
from (
    select
        cast(_c0 as int) as businessentityid
        , cast(_c1 as int) as territoryid
        , cast(_c2 as timestamp) as startdate
        , cast(_c3 as timestamp) as enddate
        , cast(_c4 as string) as rowguid
        , cast(_c5 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesTerritoryHistory.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.ShoppingCartItem: 6 colunas
copy into workspace.adventure_works.shoppingcartitem
from (
    select
        cast(_c0 as int) as shoppingcartitemid
        , cast(_c1 as string) as shoppingcartid
        , cast(_c2 as int) as quantity
        , cast(_c3 as int) as productid
        , cast(_c4 as timestamp) as datecreated
        , cast(_c5 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ShoppingCartItem.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.SpecialOffer: 11 colunas
copy into workspace.adventure_works.specialoffer
from (
    select
        cast(_c0 as int) as specialofferid
        , cast(_c1 as string) as description
        , cast(_c2 as decimal(19, 4)) as discountpct
        , cast(_c3 as string) as type
        , cast(_c4 as string) as category
        , cast(_c5 as timestamp) as startdate
        , cast(_c6 as timestamp) as enddate
        , cast(_c7 as int) as minqty
        , cast(_c8 as int) as maxqty
        , cast(_c9 as string) as rowguid
        , cast(_c10 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SpecialOffer.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.SpecialOfferProduct: 4 colunas
copy into workspace.adventure_works.specialofferproduct
from (
    select
        cast(_c0 as int) as specialofferid
        , cast(_c1 as int) as productid
        , cast(_c2 as string) as rowguid
        , cast(_c3 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SpecialOfferProduct.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');

-- Sales.Store: 6 colunas
copy into workspace.adventure_works.store
from (
    select
        cast(_c0 as int) as businessentityid
        , cast(_c1 as string) as name
        , cast(_c2 as int) as salespersonid
        , cast(_c3 as string) as demographics
        , cast(_c4 as string) as rowguid
        , cast(_c5 as timestamp) as modifieddate
    from '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Store.csv'
)
fileformat = csv
format_options (
    'sep' = '\t'
    , 'header' = 'false'
    , 'nullValue' = ''
    , 'quote' = ''
    , 'mode' = 'FAILFAST'
)
copy_options ('force' = 'true');
