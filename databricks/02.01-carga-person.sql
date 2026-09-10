-- Carga do AdventureWorks: schema Person (1 de 5)
-- 13 tabelas. Cast explicito por posicao (_c0.._cN) porque o TSV
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
