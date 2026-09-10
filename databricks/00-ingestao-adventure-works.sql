-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Ingestao do AdventureWorks
-- MAGIC
-- MAGIC Este notebook e a etapa de **EL** do desafio: cria as tabelas, carrega os arquivos do
-- MAGIC Volume e confere se o que chegou e o que saiu da origem.
-- MAGIC
-- MAGIC **Roda uma vez, de cima para baixo, ANTES do notebook de analise exploratoria.**
-- MAGIC
-- MAGIC ## Antes de rodar
-- MAGIC
-- MAGIC Os arquivos brutos precisam estar no Volume, com a pasta `AdventureWorks` subida
-- MAGIC **inteira** (`Select folder`, que preserva a estrutura):
-- MAGIC
-- MAGIC     /Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/
-- MAGIC
-- MAGIC Os nomes de tabela sao absolutos (`workspace.adventure_works.<tabela>`), entao nao
-- MAGIC depende de qual catalogo esta selecionado.
-- MAGIC
-- MAGIC ## Reexecutar e seguro
-- MAGIC
-- MAGIC O DDL usa `create or replace` e a carga usa `force = true`. Rodar tudo de novo
-- MAGIC recria e recarrega a partir do Volume, chegando ao mesmo resultado — o dado bruto
-- MAGIC mora no Volume, nao aqui. O custo de reexecutar e tempo, nao perda.
-- MAGIC
-- MAGIC ## Este notebook e gerado
-- MAGIC
-- MAGIC A fonte sao os tres arquivos de `databricks/`, que sao versionados e passam pelo
-- MAGIC sqlfluff. Editar celula aqui a mao cria duas versoes do mesmo SQL. Para mudar algo,
-- MAGIC mude o gerador e regere.
-- MAGIC

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # 1. Estrutura
-- MAGIC
-- MAGIC 65 tabelas vazias. O `install.sql` do repositorio oficial e Postgres e nao roda
-- MAGIC aqui — usa `SERIAL`, `uuid_generate_v1()` e `CREATE SCHEMA x CREATE TABLE y`.
-- MAGIC As definicoes foram traduzidas tipo por tipo.
-- MAGIC
-- MAGIC **A decisao que da razao a este bloco:** dinheiro em `decimal(19, 4)`, nunca
-- MAGIC `double`. Com inferencia de tipo, dinheiro viraria ponto flutuante e o teste de
-- MAGIC aceite do briefing (US$ 12.646.112,16) sairia arredondado.
-- MAGIC
-- MAGIC Tres tabelas ficam de fora, por defeito de origem e nao por escolha: `Document` e
-- MAGIC `ProductPhoto` tem coluna binaria, que nao atravessa arquivo de texto, e
-- MAGIC `ProductReview` esta quebrado no arquivo (7 campos onde o DDL declara 8, e quebra
-- MAGIC de linha dentro de campo).

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

-- Person.AddressType: 4 colunas
create or replace table workspace.adventure_works.addresstype (
    addresstypeid int
    , name string
    , rowguid string
    , modifieddate timestamp
);

-- COMMAND ----------

-- Person.BusinessEntityAddress: 5 colunas
create or replace table workspace.adventure_works.businessentityaddress (
    businessentityid int
    , addressid int
    , addresstypeid int
    , rowguid string
    , modifieddate timestamp
);

-- COMMAND ----------

-- Person.ContactType: 3 colunas
create or replace table workspace.adventure_works.contacttype (
    contacttypeid int
    , name string
    , modifieddate timestamp
);

-- COMMAND ----------

-- Person.BusinessEntityContact: 5 colunas
create or replace table workspace.adventure_works.businessentitycontact (
    businessentityid int
    , personid int
    , contacttypeid int
    , rowguid string
    , modifieddate timestamp
);

-- COMMAND ----------

-- Person.EmailAddress: 5 colunas
create or replace table workspace.adventure_works.emailaddress (
    businessentityid int
    , emailaddressid int
    , emailaddress string
    , rowguid string
    , modifieddate timestamp
);

-- COMMAND ----------

-- Person.Password: 5 colunas
create or replace table workspace.adventure_works.password (
    businessentityid int
    , passwordhash string
    , passwordsalt string
    , rowguid string
    , modifieddate timestamp
);

-- COMMAND ----------

-- Person.PhoneNumberType: 3 colunas
create or replace table workspace.adventure_works.phonenumbertype (
    phonenumbertypeid int
    , name string
    , modifieddate timestamp
);

-- COMMAND ----------

-- Person.PersonPhone: 4 colunas
create or replace table workspace.adventure_works.personphone (
    businessentityid int
    , phonenumber string
    , phonenumbertypeid int
    , modifieddate timestamp
);

-- COMMAND ----------

-- Person.CountryRegion: 3 colunas  -- no escopo da analise
create or replace table workspace.adventure_works.countryregion (
    countryregioncode string
    , name string
    , modifieddate timestamp
);

-- COMMAND ----------

-- HumanResources.Department: 4 colunas
create or replace table workspace.adventure_works.department (
    departmentid int
    , name string
    , groupname string
    , modifieddate timestamp
);

-- COMMAND ----------

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

-- COMMAND ----------

-- HumanResources.EmployeeDepartmentHistory: 6 colunas
create or replace table workspace.adventure_works.employeedepartmenthistory (
    businessentityid int
    , departmentid smallint
    , shiftid smallint
    , startdate timestamp
    , enddate timestamp
    , modifieddate timestamp
);

-- COMMAND ----------

-- HumanResources.EmployeePayHistory: 5 colunas
create or replace table workspace.adventure_works.employeepayhistory (
    businessentityid int
    , ratechangedate timestamp
    , rate decimal(19, 4)
    , payfrequency smallint
    , modifieddate timestamp
);

-- COMMAND ----------

-- HumanResources.JobCandidate: 4 colunas
create or replace table workspace.adventure_works.jobcandidate (
    jobcandidateid int
    , businessentityid int
    , resume string
    , modifieddate timestamp
);

-- COMMAND ----------

-- HumanResources.Shift: 5 colunas
create or replace table workspace.adventure_works.shift (
    shiftid int
    , name string
    , starttime string
    , endtime string
    , modifieddate timestamp
);

-- COMMAND ----------

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

-- COMMAND ----------

-- Production.Culture: 3 colunas
create or replace table workspace.adventure_works.culture (
    cultureid string
    , name string
    , modifieddate timestamp
);

-- COMMAND ----------

-- Production.ProductCategory: 4 colunas  -- no escopo da analise
create or replace table workspace.adventure_works.productcategory (
    productcategoryid int
    , name string
    , rowguid string
    , modifieddate timestamp
);

-- COMMAND ----------

-- Production.ProductSubcategory: 5 colunas  -- no escopo da analise
create or replace table workspace.adventure_works.productsubcategory (
    productsubcategoryid int
    , productcategoryid int
    , name string
    , rowguid string
    , modifieddate timestamp
);

-- COMMAND ----------

-- Production.ProductModel: 6 colunas
create or replace table workspace.adventure_works.productmodel (
    productmodelid int
    , name string
    , catalogdescription string
    , instructions string
    , rowguid string
    , modifieddate timestamp
);

-- COMMAND ----------

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

-- COMMAND ----------

-- Production.ProductCostHistory: 5 colunas
create or replace table workspace.adventure_works.productcosthistory (
    productid int
    , startdate timestamp
    , enddate timestamp
    , standardcost decimal(19, 4)
    , modifieddate timestamp
);

-- COMMAND ----------

-- Production.ProductDescription: 4 colunas
create or replace table workspace.adventure_works.productdescription (
    productdescriptionid int
    , description string
    , rowguid string
    , modifieddate timestamp
);

-- COMMAND ----------

-- Production.ProductDocument: 3 colunas
create or replace table workspace.adventure_works.productdocument (
    productid int
    , doc string
    , modifieddate timestamp
);

-- COMMAND ----------

-- Production.Location: 5 colunas
create or replace table workspace.adventure_works.location (
    locationid int
    , name string
    , costrate decimal(19, 4)
    , availability string
    , modifieddate timestamp
);

-- COMMAND ----------

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

-- COMMAND ----------

-- Production.ProductListPriceHistory: 5 colunas
create or replace table workspace.adventure_works.productlistpricehistory (
    productid int
    , startdate timestamp
    , enddate timestamp
    , listprice decimal(19, 4)
    , modifieddate timestamp
);

-- COMMAND ----------

-- Production.Illustration: 3 colunas
create or replace table workspace.adventure_works.illustration (
    illustrationid int
    , diagram string
    , modifieddate timestamp
);

-- COMMAND ----------

-- Production.ProductModelIllustration: 3 colunas
create or replace table workspace.adventure_works.productmodelillustration (
    productmodelid int
    , illustrationid int
    , modifieddate timestamp
);

-- COMMAND ----------

-- Production.ProductModelProductDescriptionCulture: 4 colunas
create or replace table workspace.adventure_works.productmodelproductdescriptionculture (
    productmodelid int
    , productdescriptionid int
    , cultureid string
    , modifieddate timestamp
);

-- COMMAND ----------

-- Production.ProductProductPhoto: 4 colunas
create or replace table workspace.adventure_works.productproductphoto (
    productid int
    , productphotoid int
    , `primary` boolean
    , modifieddate timestamp
);

-- COMMAND ----------

-- Production.ScrapReason: 3 colunas
create or replace table workspace.adventure_works.scrapreason (
    scrapreasonid int
    , name string
    , modifieddate timestamp
);

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

-- Production.UnitMeasure: 3 colunas
create or replace table workspace.adventure_works.unitmeasure (
    unitmeasurecode decimal(19, 4)
    , name string
    , modifieddate timestamp
);

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

-- Purchasing.ShipMethod: 6 colunas
create or replace table workspace.adventure_works.shipmethod (
    shipmethodid int
    , name string
    , shipbase decimal(19, 4)
    , shiprate decimal(19, 4)
    , rowguid string
    , modifieddate timestamp
);

-- COMMAND ----------

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

-- COMMAND ----------

-- Sales.CountryRegionCurrency: 3 colunas
create or replace table workspace.adventure_works.countryregioncurrency (
    countryregioncode string
    , currencycode string
    , modifieddate timestamp
);

-- COMMAND ----------

-- Sales.CreditCard: 6 colunas  -- no escopo da analise
create or replace table workspace.adventure_works.creditcard (
    creditcardid int
    , cardtype string
    , cardnumber string
    , expmonth smallint
    , expyear smallint
    , modifieddate timestamp
);

-- COMMAND ----------

-- Sales.Currency: 3 colunas
create or replace table workspace.adventure_works.currency (
    currencycode string
    , name string
    , modifieddate timestamp
);

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

-- Sales.PersonCreditCard: 3 colunas
create or replace table workspace.adventure_works.personcreditcard (
    businessentityid int
    , creditcardid int
    , modifieddate timestamp
);

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

-- Sales.SalesOrderHeaderSalesReason: 3 colunas  -- no escopo da analise
create or replace table workspace.adventure_works.salesorderheadersalesreason (
    salesorderid int
    , salesreasonid int
    , modifieddate timestamp
);

-- COMMAND ----------

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

-- COMMAND ----------

-- Sales.SalesPersonQuotaHistory: 5 colunas
create or replace table workspace.adventure_works.salespersonquotahistory (
    businessentityid int
    , quotadate timestamp
    , salesquota decimal(19, 4)
    , rowguid string
    , modifieddate timestamp
);

-- COMMAND ----------

-- Sales.SalesReason: 4 colunas  -- no escopo da analise
create or replace table workspace.adventure_works.salesreason (
    salesreasonid int
    , name string
    , reasontype string
    , modifieddate timestamp
);

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

-- Sales.SalesTerritoryHistory: 6 colunas
create or replace table workspace.adventure_works.salesterritoryhistory (
    businessentityid int
    , territoryid int
    , startdate timestamp
    , enddate timestamp
    , rowguid string
    , modifieddate timestamp
);

-- COMMAND ----------

-- Sales.ShoppingCartItem: 6 colunas
create or replace table workspace.adventure_works.shoppingcartitem (
    shoppingcartitemid int
    , shoppingcartid string
    , quantity int
    , productid int
    , datecreated timestamp
    , modifieddate timestamp
);

-- COMMAND ----------

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

-- COMMAND ----------

-- Sales.SpecialOfferProduct: 4 colunas
create or replace table workspace.adventure_works.specialofferproduct (
    specialofferid int
    , productid int
    , rowguid string
    , modifieddate timestamp
);

-- COMMAND ----------

-- Sales.Store: 6 colunas  -- no escopo da analise
create or replace table workspace.adventure_works.store (
    businessentityid int
    , name string
    , salespersonid int
    , demographics string
    , rowguid string
    , modifieddate timestamp
);

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 1.1 A estrutura ficou como projetada?
-- MAGIC
-- MAGIC Tres conferencias baratas antes de carregar 79 MB, cada uma com o valor esperado
-- MAGIC no comentario. Se alguma divergir, **pare** e corrija o DDL antes de seguir.
-- MAGIC
-- MAGIC 1. **As tabelas nasceram?** 65. Uma faltando so apareceria no meio da carga.
-- MAGIC 2. **Dinheiro nao virou `double`?** E a conferencia mais importante desta etapa:
-- MAGIC    com ponto flutuante, o teste de aceite do briefing sai arredondado.
-- MAGIC 3. **A precisao esta certa?** 19 e 4 — `unitpricediscount` guarda percentual, e com
-- MAGIC    escala menor que 4 o desconto arredonda e desaparece do calculo.

-- COMMAND ----------

-- Conferencia da estrutura: roda DEPOIS do 01-ddl e ANTES do 02-carga.
-- Tres consultas baratas que evitam descobrir problema no meio de 65 cargas.


-- 1. As tabelas nasceram? Tem de dar 65.
--    O install.sql tem 68; tres ficam de fora por defeito de origem.
select count(*) as tabelas_criadas
from workspace.information_schema.tables
where table_catalog = 'workspace'
    and table_schema = 'adventure_works';

-- COMMAND ----------

-- 2. Dinheiro nao virou ponto flutuante? Tem de vir DECIMAL nas tres.
--    Com double, o teste de aceite do briefing sai arredondado.
select
    column_name
    , data_type
from workspace.information_schema.columns
where table_schema = 'adventure_works'
    and table_name = 'salesorderdetail'
    and column_name in ('unitprice', 'unitpricediscount', 'linetotal');

-- COMMAND ----------

-- 3. A precisao esta certa? Tem de dar 19 e 4 nas tres.
--    data_type mostra so o tipo base; escala e precisao ficam em outras colunas.
--    unitpricediscount guarda percentual (0.0200 = 2%): com escala menor que 4,
--    o desconto arredonda e desaparece do calculo.
select
    column_name
    , data_type
    , numeric_precision
    , numeric_scale
from workspace.information_schema.columns
where table_schema = 'adventure_works'
    and table_name = 'salesorderdetail'
    and column_name in ('unitprice', 'unitpricediscount', 'linetotal');

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # 2. Carga
-- MAGIC
-- MAGIC Um `COPY INTO` por tabela, lendo do Volume, com **cast explicito por posicao**.
-- MAGIC
-- MAGIC O motivo do cast: os arquivos **nao tem linha de cabecalho**. O Databricks le as
-- MAGIC colunas como `_c0`, `_c1`, `_c2`... e a unica fonte da verdade sobre qual e qual e
-- MAGIC a ordem do `install.sql`. Nomear uma a uma torna o desalinhamento impossivel de
-- MAGIC passar batido.
-- MAGIC
-- MAGIC As quatro opcoes de formato, cada uma resolvendo uma armadilha medida nos arquivos:
-- MAGIC
-- MAGIC | Opcao | Por que |
-- MAGIC |---|---|
-- MAGIC | `'sep' = '\t'` | os arquivos tem extensao `.csv` mas sao separados por **tab** |
-- MAGIC | `'nullValue' = ''` | sem isso, campo vazio em coluna `int` recebe **0**. So no `salesorderheader` sao 27.659 pedidos sem vendedor, que viriam como "vendedor 0" |
-- MAGIC | `'quote' = ''` | o `person` tem XML com aspas dentro do campo |
-- MAGIC | `'mode' = 'FAILFAST'` | linha ruim **derruba** o comando em vez de virar NULL em silencio |
-- MAGIC
-- MAGIC Se alguma celula falhar, o erro aponta a tabela: e por isso que ha uma por celula.

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

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

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # 3. Posso confiar no que chegou?
-- MAGIC
-- MAGIC Cinco conferencias. **Se alguma falhar, nao siga para a analise** — todo numero da
-- MAGIC exploracao ficaria suspeito.
-- MAGIC
-- MAGIC 1. **Contagem por tabela** — o esperado esta embutido no SQL, medido nos proprios
-- MAGIC    arquivos de origem. Retorna `ok` ou `DIVERGE` por tabela.
-- MAGIC 2. **As sete juncoes** que a analise usa. Todas deram zero orfao nos arquivos antes
-- MAGIC    de carregar; se der diferente aqui, a carga errou.
-- MAGIC 3. **O NULL sobreviveu?** Tem de dar 27.659 pedidos sem vendedor, e zero com
-- MAGIC    "vendedor 0". E a prova de que o `nullValue` funcionou — e disso depende toda a
-- MAGIC    analise de canal, porque "sem vendedor" e o que identifica venda online.
-- MAGIC 4. **O teste de aceite do briefing** — tem de dar `12646112.16` exato e `FECHA`. E o
-- MAGIC    unico numero com verdade externa. Se vier arredondado, o tipo virou float.
-- MAGIC 5. **Integridade do `linetotal`** — nesta base o campo vem do arquivo, nao e
-- MAGIC    calculado pelo banco. Tem de dar zero linhas fora de um centavo, em 121.317.

-- COMMAND ----------

-- Verificacao da carga do AdventureWorks
-- Rodar DEPOIS do 02-carga e ANTES de qualquer analise. Se algo aqui falhar,
-- todo numero da exploracao fica suspeito.
--
-- Os valores "esperado" vem da contagem de linhas dos proprios arquivos de
-- origem, medida localmente.
/* ------------------------------------------------------------------------
   1. Contagem por tabela: o que chegou e igual ao que saiu do arquivo?
   ------------------------------------------------------------------------ */
with contagem as (
    select
        'businessentity' as tabela
        , 20777 as esperado
        , count(*) as carregado
    from workspace.adventure_works.businessentity
    union all
    select
        'person' as tabela
        , 19972 as esperado
        , count(*) as carregado
    from workspace.adventure_works.person
    union all
    select
        'stateprovince' as tabela
        , 181 as esperado
        , count(*) as carregado
    from workspace.adventure_works.stateprovince
    union all
    select
        'address' as tabela
        , 19614 as esperado
        , count(*) as carregado
    from workspace.adventure_works.address
    union all
    select
        'addresstype' as tabela
        , 6 as esperado
        , count(*) as carregado
    from workspace.adventure_works.addresstype
    union all
    select
        'businessentityaddress' as tabela
        , 19614 as esperado
        , count(*) as carregado
    from workspace.adventure_works.businessentityaddress
    union all
    select
        'contacttype' as tabela
        , 20 as esperado
        , count(*) as carregado
    from workspace.adventure_works.contacttype
    union all
    select
        'businessentitycontact' as tabela
        , 909 as esperado
        , count(*) as carregado
    from workspace.adventure_works.businessentitycontact
    union all
    select
        'emailaddress' as tabela
        , 19972 as esperado
        , count(*) as carregado
    from workspace.adventure_works.emailaddress
    union all
    select
        'password' as tabela
        , 19972 as esperado
        , count(*) as carregado
    from workspace.adventure_works.password
    union all
    select
        'phonenumbertype' as tabela
        , 3 as esperado
        , count(*) as carregado
    from workspace.adventure_works.phonenumbertype
    union all
    select
        'personphone' as tabela
        , 19972 as esperado
        , count(*) as carregado
    from workspace.adventure_works.personphone
    union all
    select
        'countryregion' as tabela
        , 238 as esperado
        , count(*) as carregado
    from workspace.adventure_works.countryregion
    union all
    select
        'department' as tabela
        , 16 as esperado
        , count(*) as carregado
    from workspace.adventure_works.department
    union all
    select
        'employee' as tabela
        , 290 as esperado
        , count(*) as carregado
    from workspace.adventure_works.employee
    union all
    select
        'employeedepartmenthistory' as tabela
        , 296 as esperado
        , count(*) as carregado
    from workspace.adventure_works.employeedepartmenthistory
    union all
    select
        'employeepayhistory' as tabela
        , 316 as esperado
        , count(*) as carregado
    from workspace.adventure_works.employeepayhistory
    union all
    select
        'jobcandidate' as tabela
        , 13 as esperado
        , count(*) as carregado
    from workspace.adventure_works.jobcandidate
    union all
    select
        'shift' as tabela
        , 3 as esperado
        , count(*) as carregado
    from workspace.adventure_works.shift
    union all
    select
        'billofmaterials' as tabela
        , 2679 as esperado
        , count(*) as carregado
    from workspace.adventure_works.billofmaterials
    union all
    select
        'culture' as tabela
        , 8 as esperado
        , count(*) as carregado
    from workspace.adventure_works.culture
    union all
    select
        'productcategory' as tabela
        , 4 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productcategory
    union all
    select
        'productsubcategory' as tabela
        , 37 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productsubcategory
    union all
    select
        'productmodel' as tabela
        , 128 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productmodel
    union all
    select
        'product' as tabela
        , 504 as esperado
        , count(*) as carregado
    from workspace.adventure_works.product
    union all
    select
        'productcosthistory' as tabela
        , 395 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productcosthistory
    union all
    select
        'productdescription' as tabela
        , 762 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productdescription
    union all
    select
        'productdocument' as tabela
        , 32 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productdocument
    union all
    select
        'location' as tabela
        , 14 as esperado
        , count(*) as carregado
    from workspace.adventure_works.location
    union all
    select
        'productinventory' as tabela
        , 1069 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productinventory
    union all
    select
        'productlistpricehistory' as tabela
        , 395 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productlistpricehistory
    union all
    select
        'illustration' as tabela
        , 5 as esperado
        , count(*) as carregado
    from workspace.adventure_works.illustration
    union all
    select
        'productmodelillustration' as tabela
        , 7 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productmodelillustration
    union all
    select
        'productmodelproductdescriptionculture' as tabela
        , 762 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productmodelproductdescriptionculture
    union all
    select
        'productproductphoto' as tabela
        , 504 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productproductphoto
    union all
    select
        'scrapreason' as tabela
        , 16 as esperado
        , count(*) as carregado
    from workspace.adventure_works.scrapreason
    union all
    select
        'transactionhistory' as tabela
        , 113443 as esperado
        , count(*) as carregado
    from workspace.adventure_works.transactionhistory
    union all
    select
        'transactionhistoryarchive' as tabela
        , 89253 as esperado
        , count(*) as carregado
    from workspace.adventure_works.transactionhistoryarchive
    union all
    select
        'unitmeasure' as tabela
        , 38 as esperado
        , count(*) as carregado
    from workspace.adventure_works.unitmeasure
    union all
    select
        'workorder' as tabela
        , 72591 as esperado
        , count(*) as carregado
    from workspace.adventure_works.workorder
    union all
    select
        'workorderrouting' as tabela
        , 67131 as esperado
        , count(*) as carregado
    from workspace.adventure_works.workorderrouting
    union all
    select
        'productvendor' as tabela
        , 460 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productvendor
    union all
    select
        'purchaseorderdetail' as tabela
        , 8845 as esperado
        , count(*) as carregado
    from workspace.adventure_works.purchaseorderdetail
    union all
    select
        'purchaseorderheader' as tabela
        , 4012 as esperado
        , count(*) as carregado
    from workspace.adventure_works.purchaseorderheader
    union all
    select
        'shipmethod' as tabela
        , 5 as esperado
        , count(*) as carregado
    from workspace.adventure_works.shipmethod
    union all
    select
        'vendor' as tabela
        , 104 as esperado
        , count(*) as carregado
    from workspace.adventure_works.vendor
    union all
    select
        'countryregioncurrency' as tabela
        , 109 as esperado
        , count(*) as carregado
    from workspace.adventure_works.countryregioncurrency
    union all
    select
        'creditcard' as tabela
        , 19118 as esperado
        , count(*) as carregado
    from workspace.adventure_works.creditcard
    union all
    select
        'currency' as tabela
        , 105 as esperado
        , count(*) as carregado
    from workspace.adventure_works.currency
    union all
    select
        'currencyrate' as tabela
        , 13532 as esperado
        , count(*) as carregado
    from workspace.adventure_works.currencyrate
    union all
    select
        'customer' as tabela
        , 19820 as esperado
        , count(*) as carregado
    from workspace.adventure_works.customer
    union all
    select
        'personcreditcard' as tabela
        , 19118 as esperado
        , count(*) as carregado
    from workspace.adventure_works.personcreditcard
    union all
    select
        'salesorderdetail' as tabela
        , 121317 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesorderdetail
    union all
    select
        'salesorderheader' as tabela
        , 31465 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesorderheader
    union all
    select
        'salesorderheadersalesreason' as tabela
        , 27647 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesorderheadersalesreason
    union all
    select
        'salesperson' as tabela
        , 17 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesperson
    union all
    select
        'salespersonquotahistory' as tabela
        , 163 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salespersonquotahistory
    union all
    select
        'salesreason' as tabela
        , 10 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesreason
    union all
    select
        'salestaxrate' as tabela
        , 29 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salestaxrate
    union all
    select
        'salesterritory' as tabela
        , 10 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesterritory
    union all
    select
        'salesterritoryhistory' as tabela
        , 17 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesterritoryhistory
    union all
    select
        'shoppingcartitem' as tabela
        , 3 as esperado
        , count(*) as carregado
    from workspace.adventure_works.shoppingcartitem
    union all
    select
        'specialoffer' as tabela
        , 16 as esperado
        , count(*) as carregado
    from workspace.adventure_works.specialoffer
    union all
    select
        'specialofferproduct' as tabela
        , 538 as esperado
        , count(*) as carregado
    from workspace.adventure_works.specialofferproduct
    union all
    select
        'store' as tabela
        , 701 as esperado
        , count(*) as carregado
    from workspace.adventure_works.store
)

select
    tabela
    , esperado
    , carregado
    , case
        when esperado = carregado then 'ok'
        else 'DIVERGE'
    end as resultado
from contagem
order by resultado desc, tabela asc;

-- COMMAND ----------

/* ------------------------------------------------------------------------
2. As sete juncoes que a analise usa: alguma tem orfao?
Todas deram zero nos arquivos; se der diferente aqui, a carga errou.
------------------------------------------------------------------------ */
select
    'pedido -> address' as juncao
    , count(*) as orfaos
from workspace.adventure_works.salesorderheader
left join workspace.adventure_works.address
    on salesorderheader.billtoaddressid = address.addressid
where address.addressid is null

union all

select
    'pedido -> customer' as juncao
    , count(*) as orfaos
from workspace.adventure_works.salesorderheader
left join workspace.adventure_works.customer
    on salesorderheader.customerid = customer.customerid
where customer.customerid is null

union all

select
    'pedido -> salesterritory' as juncao
    , count(*) as orfaos
from workspace.adventure_works.salesorderheader
left join workspace.adventure_works.salesterritory
    on salesorderheader.territoryid = salesterritory.territoryid
where salesterritory.territoryid is null

union all

select
    'pedido -> creditcard (so quem tem cartao)' as juncao
    , count(*) as orfaos
from workspace.adventure_works.salesorderheader
left join workspace.adventure_works.creditcard
    on salesorderheader.creditcardid = creditcard.creditcardid
where salesorderheader.creditcardid is not null
    and creditcard.creditcardid is null

union all

select
    'item -> product' as juncao
    , count(*) as orfaos
from workspace.adventure_works.salesorderdetail
left join workspace.adventure_works.product
    on salesorderdetail.productid = product.productid
where product.productid is null

union all

select
    'item -> specialoffer' as juncao
    , count(*) as orfaos
from workspace.adventure_works.salesorderdetail
left join workspace.adventure_works.specialoffer
    on salesorderdetail.specialofferid = specialoffer.specialofferid
where specialoffer.specialofferid is null

union all

select
    'cliente -> nome (person ou store)' as juncao
    , count(*) as orfaos
from workspace.adventure_works.customer
left join workspace.adventure_works.person
    on customer.personid = person.businessentityid
left join workspace.adventure_works.store
    on customer.storeid = store.businessentityid
where person.businessentityid is null
    and store.businessentityid is null;

-- COMMAND ----------

/* ------------------------------------------------------------------------
3. O NULL sobreviveu a carga?
27.659 pedidos nao tem vendedor. Se aparecer 0 em vez de NULL, o
nullValue do COPY INTO nao pegou e a analise de canal fica errada.
------------------------------------------------------------------------ */
select
    count(*) as pedidos
    , count(salespersonid) as com_vendedor
    , sum(case when salespersonid = 0 then 1 else 0 end) as vendedor_zero_suspeito
    , count(*) - count(salespersonid) as sem_vendedor_esperado_27659
from workspace.adventure_works.salesorderheader;

-- COMMAND ----------

/* ------------------------------------------------------------------------
4. O teste de aceite do CEO
Tem de dar 12646112.16 exato. Se vier arredondado, o tipo virou float
em algum ponto da carga.
------------------------------------------------------------------------ */
select
    12646112.16 as esperado
    , sum(salesorderdetail.unitprice * salesorderdetail.orderqty) as receita_bruta_2011
    , case
        when sum(salesorderdetail.unitprice * salesorderdetail.orderqty) = 12646112.16
            then 'FECHA'
        else 'DIVERGE'
    end as resultado
from workspace.adventure_works.salesorderdetail
inner join workspace.adventure_works.salesorderheader
    on salesorderdetail.salesorderid = salesorderheader.salesorderid
where year(salesorderheader.orderdate) = 2011;

-- COMMAND ----------

/* ------------------------------------------------------------------------
5. A integridade do linetotal
Nesta porta o campo NAO e calculado pelo banco. A identidade vale nas
121.317 linhas do arquivo; aqui confirmamos que a carga preservou.
------------------------------------------------------------------------ */
select
    count(*) as linhas
    , sum(
        case
            when abs(
                salesorderdetail.unitprice
                * (1 - salesorderdetail.unitpricediscount)
                * salesorderdetail.orderqty
                - salesorderdetail.linetotal
            ) > 0.01 then 1
            else 0
        end
    ) as fora_de_um_centavo
from workspace.adventure_works.salesorderdetail;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # Fim da ingestao
-- MAGIC
-- MAGIC Com as cinco conferencias passando, a base esta confiavel e a analise exploratoria
-- MAGIC pode comecar no notebook `02-analise-exploratoria`.
-- MAGIC
-- MAGIC A camada bruta esta **completa** (65 tabelas) de proposito: subir tudo que carrega
-- MAGIC custa 79 MB e 759 mil linhas, e remove o atrito de ingestao se o trabalho crescer
-- MAGIC para compras ou producao. O escopo **modelado** e outra decisao, e segue restrito a
-- MAGIC 17 tabelas — declarar uma tabela como source no dbt e assumir o teste e a
-- MAGIC documentacao dela.
