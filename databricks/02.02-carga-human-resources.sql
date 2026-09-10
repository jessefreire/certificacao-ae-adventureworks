-- Carga do AdventureWorks: schema HumanResources (2 de 5)
-- 6 tabelas. Cast explicito por posicao (_c0.._cN) porque o TSV
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
