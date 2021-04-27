drop table branch;
CREATE TABLE branch
AS
SELECT 	*
FROM		PROJECT2020.branch;


/*----------------------------------------------*/

drop view EMPLOYEE_DATA;
create view EMPLOYEE_DATA as

    select 
    distinct nvl(b.fname, '') || ' ' || nvl(b.mname, '') || ' ' || nvl(b.lname, '') as "name of employee",
    b.street || ' ' || b.city || ', ' || b.city || ' ' || b.state as "address",
    b.zip as "Zip code of Employee Address",
    b.ssn as "SSN",
    b.jobtitle as "Title",
    to_char(sysdate, 'YYYY') as "current year",
    
    (select c.salary 
    from EMP_ANNUAL_DATA c
    where c.year <= to_char(sysdate, 'YYYY')
    and c.empid = b.empid
    and rownum = 1) as "current yearly salary",
    
    (select c.taxdeduction 
    from EMP_ANNUAL_DATA c
    where c.year <= to_char(sysdate, 'YYYY')
    and c.empid = b.empid
    and rownum = 1) as "current year tax deduction",
    
    (select g.branchstartdate
    from branch_employee g
    where g.empid = b.empid) as "Date employee was hired",
    
    b.dob as "birth date",
    trunc(((sysdate - b.dob)/365.25),0) as "age",
    
    br.phoneext as "branch phone extension",
    
    (select NVL(e.branchphone, 'no number availible')
    from branch e
    where e.branchid = br.branchid) as "phone number",
    
    (select m.b_name
    from branch m
    where m.branchid = br.branchid) as "branch name",
    
    b.degree as "as highest degree earned",
    
    b.degreedate as "date earned degree"
    
    from Bank_employee b
    left join EMP_ANNUAL_DATA a
    on b.empid = a.empid
    left join branch_employee br
    on br.empid = b.empid
    where b.ssn is not null;
    
    SELECT	 *
    FROM 	EMPLOYEE_DATA;

        
--*********************************************************

create view Employee_salary as
    
    select 
    distinct nvl(e.fname, '') || ' ' || nvl(e.mname, '') || ' ' || nvl(e.lname, '') as "name of employee",
    
    to_Char(sysdate, 'yyyy') as "current year",
    
    e.ssn as "employee ssn",
    
    (select c.salary 
    from EMP_ANNUAL_DATA c
    where c.year <= to_char(sysdate, 'YYYY')
    and c.empid = e.empid
    and rownum = 1) as "current salary",
    
    nvl((select m.b_name
    from branch m
    where m.branchid = b.branchid), 'no branch name availible') as "branch name",
    
   nvl((select sum(ema.salary)
    from EMP_ANNUAL_DATA ema
    left join branch_employee br
    on ema.empid = br.empid
    where br.branchid  = (select x.branchid
                          from branch_employee x 
                          where e.empid = x.empid)),0)
    as "total branch salaries",
   
    nvl((select max(ema.salary)
    from EMP_ANNUAL_DATA ema
    left join branch_employee br
    on ema.empid = br.empid
    where br.branchid  = (select x.branchid
                          from branch_employee x 
                          where e.empid = x.empid)),0)
    as "highest branch salary",
    
    trunc(nvl((select avg(ema.salary)
    from EMP_ANNUAL_DATA ema
    left join branch_employee br
    on ema.empid = br.empid
    where br.branchid  = (select x.branchid
                          from branch_employee x 
                          where e.empid = x.empid)),0), 2)
    as "average branch salary"
    
    from bank_employee e
    left join branch_employee b
    on e.empid = b.empid
    left join branch a
    on b.branchid = a.branchid;
    
    select * from Employee_salary;
/*---------------------------------------------------*/
alter table branch
add fax_number number;
create or replace view Branch_data as
    select 
    br.branchid,
    br.b_name as "branch name",
    br.b_st || ' ' || br.b_city || ', ' || br.b_state || ', ' || br.b_zip as "branch address",
    nvl(br.branchphone, 'no phone listed') as "branch phone",
    br.fax_number as "branch fax number",
    (select fax_number from dual) as "fax number",
    (select count(*)
    from branch_employee be
    where br.branchid = be.branchid) as "number of branch employees",
    br.category,
    be.fname || ' ' || be.lname as "brnach manager",
    
    (select count(*)
    from DEPOSIT_ACCT_TRANSACTION dat
    where dat.accessptid = bap.accesspointid) as "number of branch transactions"
    
    from branch br
    left join  branch_manager bm
    on bm.branchid =br.branchid
    left join bank_employee be
    on bm.empid = be.empid
    left join branch_access_points bap
    on br.branchid = bap.branchid;
    
    select *
    from Branch_data;
    
/*---------------------------------------------------*/

alter table bank_customer
add email varchar2(512);

create or replace view Valued_Customers as
    select distinct
    bc.ssn,
    bc.fname || '  ' || bc.lname as "name",
    trunc(months_between(sysdate, bc.dob)/12, 0) as "age",
    bc.homephone as "home phone",
    bc.workphone as "work phone",
    bc.street || ' ' || bc.city as "address",
    bc.zip,
    bc.email,
    bc.state,
    
    (select count(cat.amount)
    from credit_acct_transaction cat
    where to_char(cast(cat.transdatetime as date), 'YYYY') = to_char(sysdate, 'YYYY')-1
    and cat.creditacctno = ca.creditacctno)
    +
    (select count(dt.amount)
    from DEPOSIT_ACCT_TRANSACTION dt
    where to_char(cast(dt.transdatetime as date), 'YYYY') = to_char(sysdate, 'YYYY')-1
    and ltrim(dt.acctno, 'CDEP0') = ltrim(ca.creditacctno, 'CCR0')) as "Total transactions",
    
    nvl((select sum(dt.amount) 
    from deposit_acct_transaction dt
    where to_char(cast(dt.transdatetime as date), 'YYYY') = to_char(sysdate, 'YYYY')-1
    and ltrim(dt.acctno, 'CDEP0') = ltrim(ca.creditacctno, 'CCR0')),0)
    +
    nvl((select sum(cat.amount)
    from credit_acct_transaction cat
    where cat.creditacctno = ca.creditacctno
    and to_char(cast(cat.transdatetime as date), 'YYYY') = to_char(sysdate, 'YYYY')-1),0)
    as "Total transaction amount"
    
    from bank_customer bc
    left join credit_account ca
    on bc.custid = ca.primary
    left join DEPOSIT_ACCt da
    on bc.custid =da.primary
    where nvl((select sum(dt.amount) 
    from deposit_acct_transaction dt
    where to_char(cast(dt.transdatetime as date), 'YYYY') = to_char(sysdate, 'YYYY')-1
    and ltrim(dt.acctno, 'CDEP0') = ltrim(ca.creditacctno, 'CCR0')),0)
    +
    nvl((select sum(cat.amount)
    from credit_acct_transaction cat
    where cat.creditacctno = ca.creditacctno
    and to_char(cast(cat.transdatetime as date), 'YYYY') = to_char(sysdate, 'YYYY')-1),0) > 500;
    
    select * from valued_customers;

/*---------------------------------------------------*/

create or replace view Statistics_by_Branch as
    select 
    b.branchid,
    b.b_name,
    to_char(sysdate, 'yyyy') as  "year",
    (select count(*) 
    from DEPOSIT_ACCT_TRANSACTION da
    left join branch_access_points bap
    on da.accessptid = bap.accesspointid
    where bap.branchid = b.branchid) as "deposits at branch",
    
    ((select count(*)
    from credit_acct_transaction cat)
    +
    (select count(*)
    from DEPOSIT_ACCT_TRANSACTION dt
    )) as "total transactions",
    
    (select count(*) 
    from bank_employee be
    left join branch_employee br
    on be.empid =br.empid
    where br.branchid = b.branchid) as "total employees at branch"
    from branch b;
    
    select * from Statistics_by_Branch;
    
/*---------------------------------------------------*/

    select * from EMP_ANNUAL_DATA;
    select * from bank_employee;
    select * from branch_employee;
    select * from CREDIT_ACCT_TRAnSACTION;
    select * from DEPOSIT_ACCt; 
    select * from DEPOSIT_ACCT_TRANSACTION;
    select * from credit_account;
    select * from DEPOSIT_ACCt_PRODUCT;
    select * from credit_account;
    select * from branch;
    select * from credit_product;
    select * from bank_customer;
    select * from loan_payment;
    select * from bank_customer;
    select * from atm;
    select * from branch_access_points;
    select * from DEPOSIT_ACCT_TRANSACTION;