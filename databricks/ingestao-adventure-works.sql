-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Ingestao do AdventureWorks
-- MAGIC
-- MAGIC Cria e carrega a camada bruta no Unity Catalog. **Nao e entregavel do desafio** — o
-- MAGIC briefing nao pede artefato de ingestao —, e sim o pre-requisito para a Etapa 2. Roda
-- MAGIC uma vez.
-- MAGIC
-- MAGIC ## Antes de rodar
-- MAGIC
-- MAGIC A pasta `AdventureWorks` inteira precisa estar num Volume, subida com `Select folder`
-- MAGIC (que preserva a estrutura de pastas):
-- MAGIC
-- MAGIC     /Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/
-- MAGIC
-- MAGIC Os nomes de tabela sao absolutos (`workspace.adventure_works.<tabela>`), entao nao depende de qual
-- MAGIC catalogo esta selecionado no editor. O nome do schema nao e escolha nossa: o briefing
-- MAGIC determina `USE SOMENTE O SCHEMA adventure_works`.
-- MAGIC
-- MAGIC ## Repetir e seguro, e isso e por construcao
-- MAGIC
-- MAGIC Cada tabela e criada e carregada em **uma** instrucao,
-- MAGIC `create or replace table ... as select`. Repetir uma celula **substitui** os dados em
-- MAGIC vez de somar, entao nao existe como duplicar.
-- MAGIC
-- MAGIC O desenho anterior separava DDL e `COPY INTO`, e ai repetir a carga somava linhas —
-- MAGIC `COPY INTO` sempre acrescenta, e `force = true` desliga a idempotencia dele. Isso
-- MAGIC chegou a deixar `address` com 3x e `employeepayhistory` com 5x as linhas. A protecao
-- MAGIC agora e propriedade do codigo, nao disciplina de quem roda.
-- MAGIC
-- MAGIC ## Onde rodar
-- MAGIC
-- MAGIC **SQL Editor ou notebook**, mas a Free Edition esgota cota de compute e devolve
-- MAGIC `RESOURCE_EXHAUSTED` — que chega disfarcado de `ValueError` do cliente gRPC. O
-- MAGIC warehouse do SQL Editor e um pool separado do compute de notebook, com cota propria,
-- MAGIC e foi por ele que a carga passou. Se estourar, espere e continue de onde parou: as
-- MAGIC celulas sao independentes.
-- MAGIC
-- MAGIC ## Ordem das secoes
-- MAGIC
-- MAGIC | Secao | Conteudo |
-- MAGIC |---|---|
-- MAGIC | 1 | As **17 tabelas** que a analise usa. Parar aqui e um estado valido |
-- MAGIC | 2 | As outras 48 da camada bruta, por schema de origem |
-- MAGIC | 3 | As conferencias. **Rodar antes de qualquer analise** |
-- MAGIC
-- MAGIC ## Este arquivo e gerado
-- MAGIC
-- MAGIC Fonte: `scripts/gera_ingestao.py`, que le o `install.sql` do repositorio oficial —
-- MAGIC de onde saem nome, ordem e tipo de cada coluna. Editar celula a mao cria duas versoes
-- MAGIC do mesmo SQL; para mudar algo, mude o gerador e regere.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # 1. As 17 tabelas da analise
-- MAGIC
-- MAGIC Vem primeiro de proposito. Sao as que as seis perguntas do briefing e os catorze
-- MAGIC aprofundamentos da Etapa 1 exigem, e as unicas que serao declaradas como `source` no
-- MAGIC dbt — declarar source e assumir o teste e a documentacao dela.
-- MAGIC
-- MAGIC Se a cota interromper a carga aqui, a Etapa 2 esta desbloqueada mesmo assim.

-- COMMAND ----------

-- Person.CountryRegion: 3 colunas
create or replace table workspace.adventure_works.countryregion as
select
    cast(_c0 as string) as countryregioncode
    , cast(_c1 as string) as name
    , cast(_c2 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/CountryRegion.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Person.StateProvince: 8 colunas
create or replace table workspace.adventure_works.stateprovince as
select
    cast(_c0 as int) as stateprovinceid
    , cast(_c1 as string) as stateprovincecode
    , cast(_c2 as string) as countryregioncode
    , cast(_c3 as boolean) as isonlystateprovinceflag
    , cast(_c4 as string) as name
    , cast(_c5 as int) as territoryid
    , cast(_c6 as string) as rowguid
    , cast(_c7 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/StateProvince.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Person.Address: 9 colunas
create or replace table workspace.adventure_works.address as
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
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Address.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Person.Person: 13 colunas
create or replace table workspace.adventure_works.person as
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
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Person.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Sales.Store: 6 colunas
create or replace table workspace.adventure_works.store as
select
    cast(_c0 as int) as businessentityid
    , cast(_c1 as string) as name
    , cast(_c2 as int) as salespersonid
    , cast(_c3 as string) as demographics
    , cast(_c4 as string) as rowguid
    , cast(_c5 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Store.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Sales.Customer: 7 colunas
create or replace table workspace.adventure_works.customer as
select
    cast(_c0 as int) as customerid
    , cast(_c1 as int) as personid
    , cast(_c2 as int) as storeid
    , cast(_c3 as int) as territoryid
    , cast(_c4 as string) as accountnumber
    , cast(_c5 as string) as rowguid
    , cast(_c6 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Customer.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Sales.CreditCard: 6 colunas
create or replace table workspace.adventure_works.creditcard as
select
    cast(_c0 as int) as creditcardid
    , cast(_c1 as string) as cardtype
    , cast(_c2 as string) as cardnumber
    , cast(_c3 as smallint) as expmonth
    , cast(_c4 as smallint) as expyear
    , cast(_c5 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/CreditCard.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Production.ProductCategory: 4 colunas
create or replace table workspace.adventure_works.productcategory as
select
    cast(_c0 as int) as productcategoryid
    , cast(_c1 as string) as name
    , cast(_c2 as string) as rowguid
    , cast(_c3 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductCategory.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Production.ProductSubcategory: 5 colunas
create or replace table workspace.adventure_works.productsubcategory as
select
    cast(_c0 as int) as productsubcategoryid
    , cast(_c1 as int) as productcategoryid
    , cast(_c2 as string) as name
    , cast(_c3 as string) as rowguid
    , cast(_c4 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductSubcategory.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Production.Product: 25 colunas
create or replace table workspace.adventure_works.product as
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
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Product.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Sales.SpecialOffer: 11 colunas
create or replace table workspace.adventure_works.specialoffer as
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
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SpecialOffer.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Sales.SalesTerritory: 10 colunas
create or replace table workspace.adventure_works.salesterritory as
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
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesTerritory.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Sales.SalesPerson: 9 colunas
create or replace table workspace.adventure_works.salesperson as
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
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesPerson.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Sales.SalesReason: 4 colunas
create or replace table workspace.adventure_works.salesreason as
select
    cast(_c0 as int) as salesreasonid
    , cast(_c1 as string) as name
    , cast(_c2 as string) as reasontype
    , cast(_c3 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesReason.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Sales.SalesOrderHeader: 26 colunas
create or replace table workspace.adventure_works.salesorderheader as
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
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesOrderHeader.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Sales.SalesOrderDetail: 11 colunas
create or replace table workspace.adventure_works.salesorderdetail as
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
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesOrderDetail.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Sales.SalesOrderHeaderSalesReason: 3 colunas
create or replace table workspace.adventure_works.salesorderheadersalesreason as
select
    cast(_c0 as int) as salesorderid
    , cast(_c1 as int) as salesreasonid
    , cast(_c2 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesOrderHeaderSalesReason.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # 2. O resto da camada bruta
-- MAGIC
-- MAGIC As outras 48 tabelas. Nenhuma pergunta do briefing usa, e a Etapa 2 nao
-- MAGIC depende delas — mas subir tudo que carrega custa quase nada (79 MB, 759 mil linhas) e
-- MAGIC remove o atrito de ingestao se o trabalho crescer para compras ou producao.
-- MAGIC
-- MAGIC Tres tabelas ficam de fora das 68 do `install.sql`, por defeito de origem e nao por
-- MAGIC escolha:
-- MAGIC
-- MAGIC - **`Document`** — coluna binaria (varbinary) nao atravessa TSV
-- MAGIC - **`ProductPhoto`** — duas colunas binarias: ThumbNailPhoto e LargePhoto
-- MAGIC - **`ProductReview`** — arquivo quebrado na origem: 7 campos onde o DDL declara 8, e quebra de linha dentro de campo (34 linhas para 31 registros)

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 2.1 Person — pessoas, endereco e geografia

-- COMMAND ----------

-- Person.BusinessEntity: 3 colunas
create or replace table workspace.adventure_works.businessentity as
select
    cast(_c0 as int) as businessentityid
    , cast(_c1 as string) as rowguid
    , cast(_c2 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/BusinessEntity.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Person.AddressType: 4 colunas
create or replace table workspace.adventure_works.addresstype as
select
    cast(_c0 as int) as addresstypeid
    , cast(_c1 as string) as name
    , cast(_c2 as string) as rowguid
    , cast(_c3 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/AddressType.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Person.BusinessEntityAddress: 5 colunas
create or replace table workspace.adventure_works.businessentityaddress as
select
    cast(_c0 as int) as businessentityid
    , cast(_c1 as int) as addressid
    , cast(_c2 as int) as addresstypeid
    , cast(_c3 as string) as rowguid
    , cast(_c4 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/BusinessEntityAddress.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Person.ContactType: 3 colunas
create or replace table workspace.adventure_works.contacttype as
select
    cast(_c0 as int) as contacttypeid
    , cast(_c1 as string) as name
    , cast(_c2 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ContactType.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Person.BusinessEntityContact: 5 colunas
create or replace table workspace.adventure_works.businessentitycontact as
select
    cast(_c0 as int) as businessentityid
    , cast(_c1 as int) as personid
    , cast(_c2 as int) as contacttypeid
    , cast(_c3 as string) as rowguid
    , cast(_c4 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/BusinessEntityContact.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Person.EmailAddress: 5 colunas
create or replace table workspace.adventure_works.emailaddress as
select
    cast(_c0 as int) as businessentityid
    , cast(_c1 as int) as emailaddressid
    , cast(_c2 as string) as emailaddress
    , cast(_c3 as string) as rowguid
    , cast(_c4 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/EmailAddress.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Person.Password: 5 colunas
create or replace table workspace.adventure_works.password as
select
    cast(_c0 as int) as businessentityid
    , cast(_c1 as string) as passwordhash
    , cast(_c2 as string) as passwordsalt
    , cast(_c3 as string) as rowguid
    , cast(_c4 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Password.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Person.PhoneNumberType: 3 colunas
create or replace table workspace.adventure_works.phonenumbertype as
select
    cast(_c0 as int) as phonenumbertypeid
    , cast(_c1 as string) as name
    , cast(_c2 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/PhoneNumberType.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Person.PersonPhone: 4 colunas
create or replace table workspace.adventure_works.personphone as
select
    cast(_c0 as int) as businessentityid
    , cast(_c1 as string) as phonenumber
    , cast(_c2 as int) as phonenumbertypeid
    , cast(_c3 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/PersonPhone.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 2.2 HumanResources — funcionarios e departamentos

-- COMMAND ----------

-- HumanResources.Department: 4 colunas
create or replace table workspace.adventure_works.department as
select
    cast(_c0 as int) as departmentid
    , cast(_c1 as string) as name
    , cast(_c2 as string) as groupname
    , cast(_c3 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Department.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- HumanResources.Employee: 16 colunas
create or replace table workspace.adventure_works.employee as
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
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Employee.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- HumanResources.EmployeeDepartmentHistory: 6 colunas
create or replace table workspace.adventure_works.employeedepartmenthistory as
select
    cast(_c0 as int) as businessentityid
    , cast(_c1 as smallint) as departmentid
    , cast(_c2 as smallint) as shiftid
    , cast(_c3 as timestamp) as startdate
    , cast(_c4 as timestamp) as enddate
    , cast(_c5 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/EmployeeDepartmentHistory.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- HumanResources.EmployeePayHistory: 5 colunas
create or replace table workspace.adventure_works.employeepayhistory as
select
    cast(_c0 as int) as businessentityid
    , cast(_c1 as timestamp) as ratechangedate
    , cast(_c2 as decimal(19, 4)) as rate
    , cast(_c3 as smallint) as payfrequency
    , cast(_c4 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/EmployeePayHistory.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- HumanResources.JobCandidate: 4 colunas
create or replace table workspace.adventure_works.jobcandidate as
select
    cast(_c0 as int) as jobcandidateid
    , cast(_c1 as int) as businessentityid
    , cast(_c2 as string) as resume
    , cast(_c3 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/JobCandidate.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- HumanResources.Shift: 5 colunas
create or replace table workspace.adventure_works.shift as
select
    cast(_c0 as int) as shiftid
    , cast(_c1 as string) as name
    , cast(_c2 as string) as starttime
    , cast(_c3 as string) as endtime
    , cast(_c4 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Shift.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 2.3 Production — produto, categoria e producao

-- COMMAND ----------

-- Production.BillOfMaterials: 9 colunas
create or replace table workspace.adventure_works.billofmaterials as
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
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/BillOfMaterials.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Production.Culture: 3 colunas
create or replace table workspace.adventure_works.culture as
select
    cast(_c0 as string) as cultureid
    , cast(_c1 as string) as name
    , cast(_c2 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Culture.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Production.ProductModel: 6 colunas
create or replace table workspace.adventure_works.productmodel as
select
    cast(_c0 as int) as productmodelid
    , cast(_c1 as string) as name
    , cast(_c2 as string) as catalogdescription
    , cast(_c3 as string) as instructions
    , cast(_c4 as string) as rowguid
    , cast(_c5 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductModel.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Production.ProductCostHistory: 5 colunas
create or replace table workspace.adventure_works.productcosthistory as
select
    cast(_c0 as int) as productid
    , cast(_c1 as timestamp) as startdate
    , cast(_c2 as timestamp) as enddate
    , cast(_c3 as decimal(19, 4)) as standardcost
    , cast(_c4 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductCostHistory.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Production.ProductDescription: 4 colunas
create or replace table workspace.adventure_works.productdescription as
select
    cast(_c0 as int) as productdescriptionid
    , cast(_c1 as string) as description
    , cast(_c2 as string) as rowguid
    , cast(_c3 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductDescription.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Production.ProductDocument: 3 colunas
create or replace table workspace.adventure_works.productdocument as
select
    cast(_c0 as int) as productid
    , cast(_c1 as string) as doc
    , cast(_c2 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductDocument.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Production.Location: 5 colunas
create or replace table workspace.adventure_works.location as
select
    cast(_c0 as int) as locationid
    , cast(_c1 as string) as name
    , cast(_c2 as decimal(19, 4)) as costrate
    , cast(_c3 as string) as availability
    , cast(_c4 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Location.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Production.ProductInventory: 7 colunas
create or replace table workspace.adventure_works.productinventory as
select
    cast(_c0 as int) as productid
    , cast(_c1 as smallint) as locationid
    , cast(_c2 as string) as shelf
    , cast(_c3 as smallint) as bin
    , cast(_c4 as smallint) as quantity
    , cast(_c5 as string) as rowguid
    , cast(_c6 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductInventory.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Production.ProductListPriceHistory: 5 colunas
create or replace table workspace.adventure_works.productlistpricehistory as
select
    cast(_c0 as int) as productid
    , cast(_c1 as timestamp) as startdate
    , cast(_c2 as timestamp) as enddate
    , cast(_c3 as decimal(19, 4)) as listprice
    , cast(_c4 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductListPriceHistory.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Production.Illustration: 3 colunas
create or replace table workspace.adventure_works.illustration as
select
    cast(_c0 as int) as illustrationid
    , cast(_c1 as string) as diagram
    , cast(_c2 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Illustration.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Production.ProductModelIllustration: 3 colunas
create or replace table workspace.adventure_works.productmodelillustration as
select
    cast(_c0 as int) as productmodelid
    , cast(_c1 as int) as illustrationid
    , cast(_c2 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductModelIllustration.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Production.ProductModelProductDescriptionCulture: 4 colunas
create or replace table workspace.adventure_works.productmodelproductdescriptionculture as
select
    cast(_c0 as int) as productmodelid
    , cast(_c1 as int) as productdescriptionid
    , cast(_c2 as string) as cultureid
    , cast(_c3 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductModelProductDescriptionCulture.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Production.ProductProductPhoto: 4 colunas
create or replace table workspace.adventure_works.productproductphoto as
select
    cast(_c0 as int) as productid
    , cast(_c1 as int) as productphotoid
    , cast(_c2 as boolean) as `primary`
    , cast(_c3 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductProductPhoto.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Production.ScrapReason: 3 colunas
create or replace table workspace.adventure_works.scrapreason as
select
    cast(_c0 as int) as scrapreasonid
    , cast(_c1 as string) as name
    , cast(_c2 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ScrapReason.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Production.TransactionHistory: 9 colunas
create or replace table workspace.adventure_works.transactionhistory as
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
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/TransactionHistory.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Production.TransactionHistoryArchive: 9 colunas
create or replace table workspace.adventure_works.transactionhistoryarchive as
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
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/TransactionHistoryArchive.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Production.UnitMeasure: 3 colunas
create or replace table workspace.adventure_works.unitmeasure as
select
    cast(_c0 as decimal(19, 4)) as unitmeasurecode
    , cast(_c1 as string) as name
    , cast(_c2 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/UnitMeasure.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Production.WorkOrder: 10 colunas
create or replace table workspace.adventure_works.workorder as
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
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/WorkOrder.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Production.WorkOrderRouting: 12 colunas
create or replace table workspace.adventure_works.workorderrouting as
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
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/WorkOrderRouting.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 2.4 Purchasing — fornecedor e compras

-- COMMAND ----------

-- Purchasing.ProductVendor: 11 colunas
create or replace table workspace.adventure_works.productvendor as
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
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ProductVendor.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Purchasing.PurchaseOrderDetail: 11 colunas
create or replace table workspace.adventure_works.purchaseorderdetail as
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
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/PurchaseOrderDetail.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Purchasing.PurchaseOrderHeader: 13 colunas
create or replace table workspace.adventure_works.purchaseorderheader as
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
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/PurchaseOrderHeader.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Purchasing.ShipMethod: 6 colunas
create or replace table workspace.adventure_works.shipmethod as
select
    cast(_c0 as int) as shipmethodid
    , cast(_c1 as string) as name
    , cast(_c2 as decimal(19, 4)) as shipbase
    , cast(_c3 as decimal(19, 4)) as shiprate
    , cast(_c4 as string) as rowguid
    , cast(_c5 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ShipMethod.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Purchasing.Vendor: 8 colunas
create or replace table workspace.adventure_works.vendor as
select
    cast(_c0 as int) as businessentityid
    , cast(_c1 as string) as accountnumber
    , cast(_c2 as string) as name
    , cast(_c3 as smallint) as creditrating
    , cast(_c4 as boolean) as preferredvendorstatus
    , cast(_c5 as boolean) as activeflag
    , cast(_c6 as string) as purchasingwebserviceurl
    , cast(_c7 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Vendor.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 2.5 Sales — pedido, item, cliente e territorio

-- COMMAND ----------

-- Sales.CountryRegionCurrency: 3 colunas
create or replace table workspace.adventure_works.countryregioncurrency as
select
    cast(_c0 as string) as countryregioncode
    , cast(_c1 as string) as currencycode
    , cast(_c2 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/CountryRegionCurrency.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Sales.Currency: 3 colunas
create or replace table workspace.adventure_works.currency as
select
    cast(_c0 as string) as currencycode
    , cast(_c1 as string) as name
    , cast(_c2 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/Currency.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Sales.CurrencyRate: 7 colunas
create or replace table workspace.adventure_works.currencyrate as
select
    cast(_c0 as int) as currencyrateid
    , cast(_c1 as timestamp) as currencyratedate
    , cast(_c2 as string) as fromcurrencycode
    , cast(_c3 as string) as tocurrencycode
    , cast(_c4 as decimal(19, 4)) as averagerate
    , cast(_c5 as decimal(19, 4)) as endofdayrate
    , cast(_c6 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/CurrencyRate.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Sales.PersonCreditCard: 3 colunas
create or replace table workspace.adventure_works.personcreditcard as
select
    cast(_c0 as int) as businessentityid
    , cast(_c1 as int) as creditcardid
    , cast(_c2 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/PersonCreditCard.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Sales.SalesPersonQuotaHistory: 5 colunas
create or replace table workspace.adventure_works.salespersonquotahistory as
select
    cast(_c0 as int) as businessentityid
    , cast(_c1 as timestamp) as quotadate
    , cast(_c2 as decimal(19, 4)) as salesquota
    , cast(_c3 as string) as rowguid
    , cast(_c4 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesPersonQuotaHistory.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Sales.SalesTaxRate: 7 colunas
create or replace table workspace.adventure_works.salestaxrate as
select
    cast(_c0 as int) as salestaxrateid
    , cast(_c1 as int) as stateprovinceid
    , cast(_c2 as smallint) as taxtype
    , cast(_c3 as decimal(19, 4)) as taxrate
    , cast(_c4 as string) as name
    , cast(_c5 as string) as rowguid
    , cast(_c6 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesTaxRate.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Sales.SalesTerritoryHistory: 6 colunas
create or replace table workspace.adventure_works.salesterritoryhistory as
select
    cast(_c0 as int) as businessentityid
    , cast(_c1 as int) as territoryid
    , cast(_c2 as timestamp) as startdate
    , cast(_c3 as timestamp) as enddate
    , cast(_c4 as string) as rowguid
    , cast(_c5 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SalesTerritoryHistory.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Sales.ShoppingCartItem: 6 colunas
create or replace table workspace.adventure_works.shoppingcartitem as
select
    cast(_c0 as int) as shoppingcartitemid
    , cast(_c1 as string) as shoppingcartid
    , cast(_c2 as int) as quantity
    , cast(_c3 as int) as productid
    , cast(_c4 as timestamp) as datecreated
    , cast(_c5 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/ShoppingCartItem.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- Sales.SpecialOfferProduct: 4 colunas
create or replace table workspace.adventure_works.specialofferproduct as
select
    cast(_c0 as int) as specialofferid
    , cast(_c1 as int) as productid
    , cast(_c2 as string) as rowguid
    , cast(_c3 as timestamp) as modifieddate
from read_files(
    '/Volumes/workspace/adventure_works/raw_adventure_works/AdventureWorks/data/SpecialOfferProduct.csv'
    , format => 'csv'
    , sep => '\t'
    , header => false
    , nullValue => ''
    , quote => ''
    , mode => 'FAILFAST'
);

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # 3. Posso confiar no que chegou?
-- MAGIC
-- MAGIC Cinco conferencias. **Se alguma falhar, nao siga para a analise** — todo numero da
-- MAGIC exploracao ficaria suspeito.
-- MAGIC
-- MAGIC Os valores esperados estao embutidos no SQL, medidos nos proprios arquivos de origem.
-- MAGIC Quem roda nao precisa saber de cor que sao 65 tabelas ou que a receita de 2011 e
-- MAGIC 12.646.112,16.

-- COMMAND ----------

-- 3.1 Dinheiro ficou exato? Tem de vir DECIMAL com 19 e 4 nas tres.
--     Com double, o teste de aceite sai arredondado e a causa fica escondida no tipo.
select
    column_name
    , data_type
    , numeric_precision
    , numeric_scale
from workspace.information_schema.columns
where table_schema = 'adventure_works'
    and table_name = 'salesorderdetail'
    and column_name in ('unitprice', 'unitpricediscount', 'linetotal')
order by column_name asc;

-- COMMAND ----------

-- 3.2 A contagem bate com o arquivo de origem? As 17 da analise tem de dar `ok`.
--     `nao carregada` em camada bruta e esperado se voce parou na secao 1.
with contagem as (
    select
        'businessentity' as tabela
        , 'camada bruta' as escopo
        , 20777 as esperado
        , count(*) as carregado
    from workspace.adventure_works.businessentity
    union all
    select
        'person' as tabela
        , 'analise' as escopo
        , 19972 as esperado
        , count(*) as carregado
    from workspace.adventure_works.person
    union all
    select
        'stateprovince' as tabela
        , 'analise' as escopo
        , 181 as esperado
        , count(*) as carregado
    from workspace.adventure_works.stateprovince
    union all
    select
        'address' as tabela
        , 'analise' as escopo
        , 19614 as esperado
        , count(*) as carregado
    from workspace.adventure_works.address
    union all
    select
        'addresstype' as tabela
        , 'camada bruta' as escopo
        , 6 as esperado
        , count(*) as carregado
    from workspace.adventure_works.addresstype
    union all
    select
        'businessentityaddress' as tabela
        , 'camada bruta' as escopo
        , 19614 as esperado
        , count(*) as carregado
    from workspace.adventure_works.businessentityaddress
    union all
    select
        'contacttype' as tabela
        , 'camada bruta' as escopo
        , 20 as esperado
        , count(*) as carregado
    from workspace.adventure_works.contacttype
    union all
    select
        'businessentitycontact' as tabela
        , 'camada bruta' as escopo
        , 909 as esperado
        , count(*) as carregado
    from workspace.adventure_works.businessentitycontact
    union all
    select
        'emailaddress' as tabela
        , 'camada bruta' as escopo
        , 19972 as esperado
        , count(*) as carregado
    from workspace.adventure_works.emailaddress
    union all
    select
        'password' as tabela
        , 'camada bruta' as escopo
        , 19972 as esperado
        , count(*) as carregado
    from workspace.adventure_works.password
    union all
    select
        'phonenumbertype' as tabela
        , 'camada bruta' as escopo
        , 3 as esperado
        , count(*) as carregado
    from workspace.adventure_works.phonenumbertype
    union all
    select
        'personphone' as tabela
        , 'camada bruta' as escopo
        , 19972 as esperado
        , count(*) as carregado
    from workspace.adventure_works.personphone
    union all
    select
        'countryregion' as tabela
        , 'analise' as escopo
        , 238 as esperado
        , count(*) as carregado
    from workspace.adventure_works.countryregion
    union all
    select
        'department' as tabela
        , 'camada bruta' as escopo
        , 16 as esperado
        , count(*) as carregado
    from workspace.adventure_works.department
    union all
    select
        'employee' as tabela
        , 'camada bruta' as escopo
        , 290 as esperado
        , count(*) as carregado
    from workspace.adventure_works.employee
    union all
    select
        'employeedepartmenthistory' as tabela
        , 'camada bruta' as escopo
        , 296 as esperado
        , count(*) as carregado
    from workspace.adventure_works.employeedepartmenthistory
    union all
    select
        'employeepayhistory' as tabela
        , 'camada bruta' as escopo
        , 316 as esperado
        , count(*) as carregado
    from workspace.adventure_works.employeepayhistory
    union all
    select
        'jobcandidate' as tabela
        , 'camada bruta' as escopo
        , 13 as esperado
        , count(*) as carregado
    from workspace.adventure_works.jobcandidate
    union all
    select
        'shift' as tabela
        , 'camada bruta' as escopo
        , 3 as esperado
        , count(*) as carregado
    from workspace.adventure_works.shift
    union all
    select
        'billofmaterials' as tabela
        , 'camada bruta' as escopo
        , 2679 as esperado
        , count(*) as carregado
    from workspace.adventure_works.billofmaterials
    union all
    select
        'culture' as tabela
        , 'camada bruta' as escopo
        , 8 as esperado
        , count(*) as carregado
    from workspace.adventure_works.culture
    union all
    select
        'productcategory' as tabela
        , 'analise' as escopo
        , 4 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productcategory
    union all
    select
        'productsubcategory' as tabela
        , 'analise' as escopo
        , 37 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productsubcategory
    union all
    select
        'productmodel' as tabela
        , 'camada bruta' as escopo
        , 128 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productmodel
    union all
    select
        'product' as tabela
        , 'analise' as escopo
        , 504 as esperado
        , count(*) as carregado
    from workspace.adventure_works.product
    union all
    select
        'productcosthistory' as tabela
        , 'camada bruta' as escopo
        , 395 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productcosthistory
    union all
    select
        'productdescription' as tabela
        , 'camada bruta' as escopo
        , 762 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productdescription
    union all
    select
        'productdocument' as tabela
        , 'camada bruta' as escopo
        , 32 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productdocument
    union all
    select
        'location' as tabela
        , 'camada bruta' as escopo
        , 14 as esperado
        , count(*) as carregado
    from workspace.adventure_works.location
    union all
    select
        'productinventory' as tabela
        , 'camada bruta' as escopo
        , 1069 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productinventory
    union all
    select
        'productlistpricehistory' as tabela
        , 'camada bruta' as escopo
        , 395 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productlistpricehistory
    union all
    select
        'illustration' as tabela
        , 'camada bruta' as escopo
        , 5 as esperado
        , count(*) as carregado
    from workspace.adventure_works.illustration
    union all
    select
        'productmodelillustration' as tabela
        , 'camada bruta' as escopo
        , 7 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productmodelillustration
    union all
    select
        'productmodelproductdescriptionculture' as tabela
        , 'camada bruta' as escopo
        , 762 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productmodelproductdescriptionculture
    union all
    select
        'productproductphoto' as tabela
        , 'camada bruta' as escopo
        , 504 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productproductphoto
    union all
    select
        'scrapreason' as tabela
        , 'camada bruta' as escopo
        , 16 as esperado
        , count(*) as carregado
    from workspace.adventure_works.scrapreason
    union all
    select
        'transactionhistory' as tabela
        , 'camada bruta' as escopo
        , 113443 as esperado
        , count(*) as carregado
    from workspace.adventure_works.transactionhistory
    union all
    select
        'transactionhistoryarchive' as tabela
        , 'camada bruta' as escopo
        , 89253 as esperado
        , count(*) as carregado
    from workspace.adventure_works.transactionhistoryarchive
    union all
    select
        'unitmeasure' as tabela
        , 'camada bruta' as escopo
        , 38 as esperado
        , count(*) as carregado
    from workspace.adventure_works.unitmeasure
    union all
    select
        'workorder' as tabela
        , 'camada bruta' as escopo
        , 72591 as esperado
        , count(*) as carregado
    from workspace.adventure_works.workorder
    union all
    select
        'workorderrouting' as tabela
        , 'camada bruta' as escopo
        , 67131 as esperado
        , count(*) as carregado
    from workspace.adventure_works.workorderrouting
    union all
    select
        'productvendor' as tabela
        , 'camada bruta' as escopo
        , 460 as esperado
        , count(*) as carregado
    from workspace.adventure_works.productvendor
    union all
    select
        'purchaseorderdetail' as tabela
        , 'camada bruta' as escopo
        , 8845 as esperado
        , count(*) as carregado
    from workspace.adventure_works.purchaseorderdetail
    union all
    select
        'purchaseorderheader' as tabela
        , 'camada bruta' as escopo
        , 4012 as esperado
        , count(*) as carregado
    from workspace.adventure_works.purchaseorderheader
    union all
    select
        'shipmethod' as tabela
        , 'camada bruta' as escopo
        , 5 as esperado
        , count(*) as carregado
    from workspace.adventure_works.shipmethod
    union all
    select
        'vendor' as tabela
        , 'camada bruta' as escopo
        , 104 as esperado
        , count(*) as carregado
    from workspace.adventure_works.vendor
    union all
    select
        'countryregioncurrency' as tabela
        , 'camada bruta' as escopo
        , 109 as esperado
        , count(*) as carregado
    from workspace.adventure_works.countryregioncurrency
    union all
    select
        'creditcard' as tabela
        , 'analise' as escopo
        , 19118 as esperado
        , count(*) as carregado
    from workspace.adventure_works.creditcard
    union all
    select
        'currency' as tabela
        , 'camada bruta' as escopo
        , 105 as esperado
        , count(*) as carregado
    from workspace.adventure_works.currency
    union all
    select
        'currencyrate' as tabela
        , 'camada bruta' as escopo
        , 13532 as esperado
        , count(*) as carregado
    from workspace.adventure_works.currencyrate
    union all
    select
        'customer' as tabela
        , 'analise' as escopo
        , 19820 as esperado
        , count(*) as carregado
    from workspace.adventure_works.customer
    union all
    select
        'personcreditcard' as tabela
        , 'camada bruta' as escopo
        , 19118 as esperado
        , count(*) as carregado
    from workspace.adventure_works.personcreditcard
    union all
    select
        'salesorderdetail' as tabela
        , 'analise' as escopo
        , 121317 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesorderdetail
    union all
    select
        'salesorderheader' as tabela
        , 'analise' as escopo
        , 31465 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesorderheader
    union all
    select
        'salesorderheadersalesreason' as tabela
        , 'analise' as escopo
        , 27647 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesorderheadersalesreason
    union all
    select
        'salesperson' as tabela
        , 'analise' as escopo
        , 17 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesperson
    union all
    select
        'salespersonquotahistory' as tabela
        , 'camada bruta' as escopo
        , 163 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salespersonquotahistory
    union all
    select
        'salesreason' as tabela
        , 'analise' as escopo
        , 10 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesreason
    union all
    select
        'salestaxrate' as tabela
        , 'camada bruta' as escopo
        , 29 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salestaxrate
    union all
    select
        'salesterritory' as tabela
        , 'analise' as escopo
        , 10 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesterritory
    union all
    select
        'salesterritoryhistory' as tabela
        , 'camada bruta' as escopo
        , 17 as esperado
        , count(*) as carregado
    from workspace.adventure_works.salesterritoryhistory
    union all
    select
        'shoppingcartitem' as tabela
        , 'camada bruta' as escopo
        , 3 as esperado
        , count(*) as carregado
    from workspace.adventure_works.shoppingcartitem
    union all
    select
        'specialoffer' as tabela
        , 'analise' as escopo
        , 16 as esperado
        , count(*) as carregado
    from workspace.adventure_works.specialoffer
    union all
    select
        'specialofferproduct' as tabela
        , 'camada bruta' as escopo
        , 538 as esperado
        , count(*) as carregado
    from workspace.adventure_works.specialofferproduct
    union all
    select
        'store' as tabela
        , 'analise' as escopo
        , 701 as esperado
        , count(*) as carregado
    from workspace.adventure_works.store
)

select
    tabela
    , escopo
    , esperado
    , carregado
    , case
        when esperado = carregado then 'ok'
        when carregado = 0 then 'nao carregada'
        else 'DIVERGE'
    end as resultado
from contagem
order by
    escopo asc
    , resultado desc
    , tabela asc;

-- COMMAND ----------

-- 3.3 As sete juncoes que a analise usa: alguma tem orfao? Tem de dar ZERO em todas.
--     Todas deram zero nos arquivos antes da carga; diferente aqui significa carga errada.
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

-- 3.4 O NULL sobreviveu? Tem de dar 27.659 sem vendedor e ZERO com vendedor 0.
--     Sem o nullValue, campo vazio em coluna int recebe 0 e inventa um vendedor.
select
    count(*) as pedidos
    , count(salespersonid) as com_vendedor
    , sum(case when salespersonid = 0 then 1 else 0 end) as vendedor_zero_suspeito
    , count(*) - count(salespersonid) as sem_vendedor_esperado_27659
from workspace.adventure_works.salesorderheader;

-- COMMAND ----------

-- 3.5 O teste de aceite do briefing. Tem de dar FECHA.
--     Soma exata = 12646112.1607; o briefing informa arredondado a centavos, porque
--     unitprice tem 4 casas e 2.832 dos 5.642 itens de 2011 usam as quatro.
select
    12646112.16 as esperado_em_centavos
    , sum(salesorderdetail.unitprice * salesorderdetail.orderqty) as receita_bruta_2011
    , case
        when round(sum(salesorderdetail.unitprice * salesorderdetail.orderqty), 2)
            = 12646112.16
            then 'FECHA'
        else 'DIVERGE'
    end as resultado
from workspace.adventure_works.salesorderdetail
inner join workspace.adventure_works.salesorderheader
    on salesorderdetail.salesorderid = salesorderheader.salesorderid
where year(salesorderheader.orderdate) = 2011;

-- COMMAND ----------

-- 3.6 A integridade do linetotal. Tem de dar 121317 linhas e ZERO fora de um centavo.
--     Nesta base o campo vem do arquivo, nao e calculado pelo banco.
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
-- MAGIC Com as conferencias passando, a base esta confiavel e a analise exploratoria pode
-- MAGIC comecar em `databricks/02-analise-exploratoria.py`.
