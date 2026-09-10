-- Carga do AdventureWorks: schema Production (3 de 5)
-- 22 tabelas. Cast explicito por posicao (_c0.._cN) porque o TSV
-- nao tem cabecalho.
--
-- Por que a carga vem quebrada em cinco arquivos: rodar as 65 instrucoes de
-- uma vez estoura o limite de recurso da Free Edition (RESOURCE_EXHAUSTED).
-- O corte segue os cinco schemas da origem, entao cada arquivo e uma area do
-- negocio. Rodar na ordem 02.01 a 02.05 e o esperado, mas eles sao
-- independentes entre si: cada tabela le do seu proprio arquivo.
--
-- nullValue = '' e obrigatorio: sem ele, coluna int com campo vazio recebe
-- 0 em vez de NULL. So no salesorderheader sao 27.659 pedidos sem vendedor.
--
-- CUIDADO: rodar este arquivo duas vezes DUPLICA as linhas. O COPY INTO
-- sempre acrescenta, e `force = true` desliga a protecao de idempotencia
-- que ignoraria arquivo ja carregado. Para recarregar, use o
-- 02.99-recarga-limpa.sql, que esvazia a tabela antes.
--
-- Nome em tres niveis de proposito: nao depende do catalogo selecionado no
-- editor. O `use catalog` faria o mesmo, mas quebra o parser do sqlfluff 1.4.5.

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
