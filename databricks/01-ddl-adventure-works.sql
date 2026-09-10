-- DDL do AdventureWorks para Databricks (Unity Catalog)
-- Gerado a partir do install.sql (Postgres) do repositorio oficial: a porta de
-- Lorin Thwaits do 'Adventure Works 2014 OLTP Script' da Microsoft. Vendas de
-- mai/2011 a jun/2014. O diagrama do briefing diz 2008 porque e a imagem do
-- SQL Server, nao esta base.
--
-- 65 tabelas. O install.sql tem 68; tres ficam de fora por defeito
-- de origem, nao por escolha:
--   Document: coluna binaria (varbinary) nao atravessa TSV
--   ProductPhoto: duas colunas binarias: ThumbNailPhoto e LargePhoto
--   ProductReview: arquivo quebrado na origem: 7 campos onde o DDL declara 8, e quebra de
--     linha dentro de campo (34 linhas para 31 registros)
--
-- Camada bruta COMPLETA de proposito: subir tudo que carrega custa quase
-- nada e remove o atrito de ingestao se o trabalho crescer para outras
-- areas. O que se declara como source no dbt e outra decisao, e segue
-- restrita ao que a analise usa (marcado nos comentarios abaixo).
--
-- Dinheiro em decimal(19, 4): o teste de aceite do CEO tem de fechar ao
-- centavo, e double nao garante isso.
--
-- Backtick so onde o Spark exige. A camada bruta espelha a origem,
-- inclusive nomes que sao palavra reservada; o rename acontece no modelo
-- de source do dbt. Ver databricks/.sqlfluff.
--
-- Nome em tres niveis (catalogo.schema.tabela) de proposito: nao depende do
-- catalogo selecionado no editor. Rodar com outro catalogo corrente criaria
-- as tabelas no lugar errado, sem erro nenhum. O `use catalog` faria o mesmo,
-- mas o sqlfluff 1.4.5 nao parseia essa sintaxe e o arquivo deixaria de ser
-- linteado.

-- Person.BusinessEntity: 3 colunas
create or replace table workspace.adventure_works.businessentity (
    businessentityid int
    , rowguid string
    , modifieddate timestamp
);

-- Person.Person: 13 colunas  -- no escopo da analise
create or replace table workspace.adventure_works.person (
    businessentityid int
    , persontype string
    , namestyle boolean
    , title string
    , firstname string
    , middlename string
    , lastname string
    , suffix string
    , emailpromotion int
    , additionalcontactinfo string
    , demographics string
    , rowguid string
    , modifieddate timestamp
);

-- Person.StateProvince: 8 colunas  -- no escopo da analise
create or replace table workspace.adventure_works.stateprovince (
    stateprovinceid int
    , stateprovincecode string
    , countryregioncode string
    , isonlystateprovinceflag boolean
    , name string
    , territoryid int
    , rowguid string
    , modifieddate timestamp
);

-- Person.Address: 9 colunas  -- no escopo da analise
create or replace table workspace.adventure_works.address (
    addressid int
    , addressline1 string
    , addressline2 string
    , city string
    , stateprovinceid int
    , postalcode string
    , spatiallocation string
    , rowguid string
    , modifieddate timestamp
);

-- Person.AddressType: 4 colunas
create or replace table workspace.adventure_works.addresstype (
    addresstypeid int
    , name string
    , rowguid string
    , modifieddate timestamp
);

-- Person.BusinessEntityAddress: 5 colunas
create or replace table workspace.adventure_works.businessentityaddress (
    businessentityid int
    , addressid int
    , addresstypeid int
    , rowguid string
    , modifieddate timestamp
);

-- Person.ContactType: 3 colunas
create or replace table workspace.adventure_works.contacttype (
    contacttypeid int
    , name string
    , modifieddate timestamp
);

-- Person.BusinessEntityContact: 5 colunas
create or replace table workspace.adventure_works.businessentitycontact (
    businessentityid int
    , personid int
    , contacttypeid int
    , rowguid string
    , modifieddate timestamp
);

-- Person.EmailAddress: 5 colunas
create or replace table workspace.adventure_works.emailaddress (
    businessentityid int
    , emailaddressid int
    , emailaddress string
    , rowguid string
    , modifieddate timestamp
);

-- Person.Password: 5 colunas
create or replace table workspace.adventure_works.password (
    businessentityid int
    , passwordhash string
    , passwordsalt string
    , rowguid string
    , modifieddate timestamp
);

-- Person.PhoneNumberType: 3 colunas
create or replace table workspace.adventure_works.phonenumbertype (
    phonenumbertypeid int
    , name string
    , modifieddate timestamp
);

-- Person.PersonPhone: 4 colunas
create or replace table workspace.adventure_works.personphone (
    businessentityid int
    , phonenumber string
    , phonenumbertypeid int
    , modifieddate timestamp
);

-- Person.CountryRegion: 3 colunas  -- no escopo da analise
create or replace table workspace.adventure_works.countryregion (
    countryregioncode string
    , name string
    , modifieddate timestamp
);

-- HumanResources.Department: 4 colunas
create or replace table workspace.adventure_works.department (
    departmentid int
    , name string
    , groupname string
    , modifieddate timestamp
);

-- HumanResources.Employee: 16 colunas
create or replace table workspace.adventure_works.employee (
    businessentityid int
    , nationalidnumber string
    , loginid string
    , org string
    , organizationlevel int
    , jobtitle string
    , birthdate timestamp
    , maritalstatus string
    , gender string
    , hiredate timestamp
    , salariedflag boolean
    , vacationhours smallint
    , sickleavehours smallint
    , currentflag boolean
    , rowguid string
    , modifieddate timestamp
);

-- HumanResources.EmployeeDepartmentHistory: 6 colunas
create or replace table workspace.adventure_works.employeedepartmenthistory (
    businessentityid int
    , departmentid smallint
    , shiftid smallint
    , startdate timestamp
    , enddate timestamp
    , modifieddate timestamp
);

-- HumanResources.EmployeePayHistory: 5 colunas
create or replace table workspace.adventure_works.employeepayhistory (
    businessentityid int
    , ratechangedate timestamp
    , rate decimal(19, 4)
    , payfrequency smallint
    , modifieddate timestamp
);

-- HumanResources.JobCandidate: 4 colunas
create or replace table workspace.adventure_works.jobcandidate (
    jobcandidateid int
    , businessentityid int
    , resume string
    , modifieddate timestamp
);

-- HumanResources.Shift: 5 colunas
create or replace table workspace.adventure_works.shift (
    shiftid int
    , name string
    , starttime string
    , endtime string
    , modifieddate timestamp
);

-- Production.BillOfMaterials: 9 colunas
create or replace table workspace.adventure_works.billofmaterials (
    billofmaterialsid int
    , productassemblyid int
    , componentid int
    , startdate timestamp
    , enddate timestamp
    , unitmeasurecode decimal(19, 4)
    , bomlevel smallint
    , perassemblyqty string
    , modifieddate timestamp
);

-- Production.Culture: 3 colunas
create or replace table workspace.adventure_works.culture (
    cultureid string
    , name string
    , modifieddate timestamp
);

-- Production.ProductCategory: 4 colunas  -- no escopo da analise
create or replace table workspace.adventure_works.productcategory (
    productcategoryid int
    , name string
    , rowguid string
    , modifieddate timestamp
);

-- Production.ProductSubcategory: 5 colunas  -- no escopo da analise
create or replace table workspace.adventure_works.productsubcategory (
    productsubcategoryid int
    , productcategoryid int
    , name string
    , rowguid string
    , modifieddate timestamp
);

-- Production.ProductModel: 6 colunas
create or replace table workspace.adventure_works.productmodel (
    productmodelid int
    , name string
    , catalogdescription string
    , instructions string
    , rowguid string
    , modifieddate timestamp
);

-- Production.Product: 25 colunas  -- no escopo da analise
create or replace table workspace.adventure_works.product (
    productid int
    , name string
    , productnumber string
    , makeflag boolean
    , finishedgoodsflag boolean
    , color string
    , safetystocklevel smallint
    , reorderpoint smallint
    , standardcost decimal(19, 4)
    , listprice decimal(19, 4)
    , size string
    , sizeunitmeasurecode string
    , weightunitmeasurecode string
    , weight decimal(19, 4)
    , daystomanufacture int
    , productline string
    , class string
    , style string
    , productsubcategoryid int
    , productmodelid int
    , sellstartdate timestamp
    , sellenddate timestamp
    , discontinueddate timestamp
    , rowguid string
    , modifieddate timestamp
);

-- Production.ProductCostHistory: 5 colunas
create or replace table workspace.adventure_works.productcosthistory (
    productid int
    , startdate timestamp
    , enddate timestamp
    , standardcost decimal(19, 4)
    , modifieddate timestamp
);

-- Production.ProductDescription: 4 colunas
create or replace table workspace.adventure_works.productdescription (
    productdescriptionid int
    , description string
    , rowguid string
    , modifieddate timestamp
);

-- Production.ProductDocument: 3 colunas
create or replace table workspace.adventure_works.productdocument (
    productid int
    , doc string
    , modifieddate timestamp
);

-- Production.Location: 5 colunas
create or replace table workspace.adventure_works.location (
    locationid int
    , name string
    , costrate decimal(19, 4)
    , availability string
    , modifieddate timestamp
);

-- Production.ProductInventory: 7 colunas
create or replace table workspace.adventure_works.productinventory (
    productid int
    , locationid smallint
    , shelf string
    , bin smallint
    , quantity smallint
    , rowguid string
    , modifieddate timestamp
);

-- Production.ProductListPriceHistory: 5 colunas
create or replace table workspace.adventure_works.productlistpricehistory (
    productid int
    , startdate timestamp
    , enddate timestamp
    , listprice decimal(19, 4)
    , modifieddate timestamp
);

-- Production.Illustration: 3 colunas
create or replace table workspace.adventure_works.illustration (
    illustrationid int
    , diagram string
    , modifieddate timestamp
);

-- Production.ProductModelIllustration: 3 colunas
create or replace table workspace.adventure_works.productmodelillustration (
    productmodelid int
    , illustrationid int
    , modifieddate timestamp
);

-- Production.ProductModelProductDescriptionCulture: 4 colunas
create or replace table workspace.adventure_works.productmodelproductdescriptionculture (
    productmodelid int
    , productdescriptionid int
    , cultureid string
    , modifieddate timestamp
);

-- Production.ProductProductPhoto: 4 colunas
create or replace table workspace.adventure_works.productproductphoto (
    productid int
    , productphotoid int
    , `primary` boolean
    , modifieddate timestamp
);

-- Production.ScrapReason: 3 colunas
create or replace table workspace.adventure_works.scrapreason (
    scrapreasonid int
    , name string
    , modifieddate timestamp
);

-- Production.TransactionHistory: 9 colunas
create or replace table workspace.adventure_works.transactionhistory (
    transactionid int
    , productid int
    , referenceorderid int
    , referenceorderlineid int
    , transactiondate timestamp
    , transactiontype string
    , quantity int
    , actualcost decimal(19, 4)
    , modifieddate timestamp
);

-- Production.TransactionHistoryArchive: 9 colunas
create or replace table workspace.adventure_works.transactionhistoryarchive (
    transactionid int
    , productid int
    , referenceorderid int
    , referenceorderlineid int
    , transactiondate timestamp
    , transactiontype string
    , quantity int
    , actualcost decimal(19, 4)
    , modifieddate timestamp
);

-- Production.UnitMeasure: 3 colunas
create or replace table workspace.adventure_works.unitmeasure (
    unitmeasurecode decimal(19, 4)
    , name string
    , modifieddate timestamp
);

-- Production.WorkOrder: 10 colunas
create or replace table workspace.adventure_works.workorder (
    workorderid int
    , productid int
    , orderqty int
    , stockedqty int
    , scrappedqty smallint
    , startdate timestamp
    , enddate timestamp
    , duedate timestamp
    , scrapreasonid smallint
    , modifieddate timestamp
);

-- Production.WorkOrderRouting: 12 colunas
create or replace table workspace.adventure_works.workorderrouting (
    workorderid int
    , productid int
    , operationsequence smallint
    , locationid smallint
    , scheduledstartdate timestamp
    , scheduledenddate timestamp
    , actualstartdate timestamp
    , actualenddate timestamp
    , actualresourcehrs string
    , plannedcost decimal(19, 4)
    , actualcost decimal(19, 4)
    , modifieddate timestamp
);

-- Purchasing.ProductVendor: 11 colunas
create or replace table workspace.adventure_works.productvendor (
    productid int
    , businessentityid int
    , averageleadtime decimal(19, 4)
    , standardprice decimal(19, 4)
    , lastreceiptcost decimal(19, 4)
    , lastreceiptdate timestamp
    , minorderqty decimal(19, 4)
    , maxorderqty decimal(19, 4)
    , onorderqty decimal(19, 4)
    , unitmeasurecode decimal(19, 4)
    , modifieddate timestamp
);

-- Purchasing.PurchaseOrderDetail: 11 colunas
create or replace table workspace.adventure_works.purchaseorderdetail (
    purchaseorderid int
    , purchaseorderdetailid int
    , duedate timestamp
    , orderqty smallint
    , productid int
    , unitprice decimal(19, 4)
    , linetotal decimal(19, 4)
    , receivedqty string
    , rejectedqty string
    , stockedqty decimal(19, 4)
    , modifieddate timestamp
);

-- Purchasing.PurchaseOrderHeader: 13 colunas
create or replace table workspace.adventure_works.purchaseorderheader (
    purchaseorderid int
    , revisionnumber smallint
    , status smallint
    , employeeid int
    , vendorid int
    , shipmethodid int
    , orderdate timestamp
    , shipdate timestamp
    , subtotal decimal(19, 4)
    , taxamt decimal(19, 4)
    , freight decimal(19, 4)
    , totaldue decimal(19, 4)
    , modifieddate timestamp
);

-- Purchasing.ShipMethod: 6 colunas
create or replace table workspace.adventure_works.shipmethod (
    shipmethodid int
    , name string
    , shipbase decimal(19, 4)
    , shiprate decimal(19, 4)
    , rowguid string
    , modifieddate timestamp
);

-- Purchasing.Vendor: 8 colunas
create or replace table workspace.adventure_works.vendor (
    businessentityid int
    , accountnumber string
    , name string
    , creditrating smallint
    , preferredvendorstatus boolean
    , activeflag boolean
    , purchasingwebserviceurl string
    , modifieddate timestamp
);

-- Sales.CountryRegionCurrency: 3 colunas
create or replace table workspace.adventure_works.countryregioncurrency (
    countryregioncode string
    , currencycode string
    , modifieddate timestamp
);

-- Sales.CreditCard: 6 colunas  -- no escopo da analise
create or replace table workspace.adventure_works.creditcard (
    creditcardid int
    , cardtype string
    , cardnumber string
    , expmonth smallint
    , expyear smallint
    , modifieddate timestamp
);

-- Sales.Currency: 3 colunas
create or replace table workspace.adventure_works.currency (
    currencycode string
    , name string
    , modifieddate timestamp
);

-- Sales.CurrencyRate: 7 colunas
create or replace table workspace.adventure_works.currencyrate (
    currencyrateid int
    , currencyratedate timestamp
    , fromcurrencycode string
    , tocurrencycode string
    , averagerate decimal(19, 4)
    , endofdayrate decimal(19, 4)
    , modifieddate timestamp
);

-- Sales.Customer: 7 colunas  -- no escopo da analise
create or replace table workspace.adventure_works.customer (
    customerid int
    , personid int
    , storeid int
    , territoryid int
    , accountnumber string
    , rowguid string
    , modifieddate timestamp
);

-- Sales.PersonCreditCard: 3 colunas
create or replace table workspace.adventure_works.personcreditcard (
    businessentityid int
    , creditcardid int
    , modifieddate timestamp
);

-- Sales.SalesOrderDetail: 11 colunas  -- no escopo da analise
create or replace table workspace.adventure_works.salesorderdetail (
    salesorderid int
    , salesorderdetailid int
    , carriertrackingnumber string
    , orderqty smallint
    , productid int
    , specialofferid int
    , unitprice decimal(19, 4)
    , unitpricediscount decimal(19, 4)
    , linetotal decimal(19, 4)
    , rowguid string
    , modifieddate timestamp
);

-- Sales.SalesOrderHeader: 26 colunas  -- no escopo da analise
create or replace table workspace.adventure_works.salesorderheader (
    salesorderid int
    , revisionnumber smallint
    , orderdate timestamp
    , duedate timestamp
    , shipdate timestamp
    , status smallint
    , onlineorderflag boolean
    , salesordernumber string
    , purchaseordernumber string
    , accountnumber string
    , customerid int
    , salespersonid int
    , territoryid int
    , billtoaddressid int
    , shiptoaddressid int
    , shipmethodid int
    , creditcardid int
    , creditcardapprovalcode string
    , currencyrateid int
    , subtotal decimal(19, 4)
    , taxamt decimal(19, 4)
    , freight decimal(19, 4)
    , totaldue decimal(19, 4)
    , comment string
    , rowguid string
    , modifieddate timestamp
);

-- Sales.SalesOrderHeaderSalesReason: 3 colunas  -- no escopo da analise
create or replace table workspace.adventure_works.salesorderheadersalesreason (
    salesorderid int
    , salesreasonid int
    , modifieddate timestamp
);

-- Sales.SalesPerson: 9 colunas  -- no escopo da analise
create or replace table workspace.adventure_works.salesperson (
    businessentityid int
    , territoryid int
    , salesquota decimal(19, 4)
    , bonus decimal(19, 4)
    , commissionpct decimal(19, 4)
    , salesytd decimal(19, 4)
    , saleslastyear decimal(19, 4)
    , rowguid string
    , modifieddate timestamp
);

-- Sales.SalesPersonQuotaHistory: 5 colunas
create or replace table workspace.adventure_works.salespersonquotahistory (
    businessentityid int
    , quotadate timestamp
    , salesquota decimal(19, 4)
    , rowguid string
    , modifieddate timestamp
);

-- Sales.SalesReason: 4 colunas  -- no escopo da analise
create or replace table workspace.adventure_works.salesreason (
    salesreasonid int
    , name string
    , reasontype string
    , modifieddate timestamp
);

-- Sales.SalesTaxRate: 7 colunas
create or replace table workspace.adventure_works.salestaxrate (
    salestaxrateid int
    , stateprovinceid int
    , taxtype smallint
    , taxrate decimal(19, 4)
    , name string
    , rowguid string
    , modifieddate timestamp
);

-- Sales.SalesTerritory: 10 colunas  -- no escopo da analise
create or replace table workspace.adventure_works.salesterritory (
    territoryid int
    , name string
    , countryregioncode string
    , `group` string
    , salesytd decimal(19, 4)
    , saleslastyear decimal(19, 4)
    , costytd decimal(19, 4)
    , costlastyear decimal(19, 4)
    , rowguid string
    , modifieddate timestamp
);

-- Sales.SalesTerritoryHistory: 6 colunas
create or replace table workspace.adventure_works.salesterritoryhistory (
    businessentityid int
    , territoryid int
    , startdate timestamp
    , enddate timestamp
    , rowguid string
    , modifieddate timestamp
);

-- Sales.ShoppingCartItem: 6 colunas
create or replace table workspace.adventure_works.shoppingcartitem (
    shoppingcartitemid int
    , shoppingcartid string
    , quantity int
    , productid int
    , datecreated timestamp
    , modifieddate timestamp
);

-- Sales.SpecialOffer: 11 colunas  -- no escopo da analise
create or replace table workspace.adventure_works.specialoffer (
    specialofferid int
    , description string
    , discountpct decimal(19, 4)
    , type string
    , category string
    , startdate timestamp
    , enddate timestamp
    , minqty int
    , maxqty int
    , rowguid string
    , modifieddate timestamp
);

-- Sales.SpecialOfferProduct: 4 colunas
create or replace table workspace.adventure_works.specialofferproduct (
    specialofferid int
    , productid int
    , rowguid string
    , modifieddate timestamp
);

-- Sales.Store: 6 colunas  -- no escopo da analise
create or replace table workspace.adventure_works.store (
    businessentityid int
    , name string
    , salespersonid int
    , demographics string
    , rowguid string
    , modifieddate timestamp
);
