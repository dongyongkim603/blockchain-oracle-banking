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

create or replace view Customer_Loan_Data as
    select 
    bc.Fname || ' ' || bc.lname as "customer name",
    bc.custid as "customer id",
    l.amtborrowed as "amount borrowed",
    trunc(((sysdate - l.dateissued)/365), 2) as "age of loan in years",
    lp.descrip || ' ' || lp.category as "type of loan",
    l.mopaydueday || 'th' as "Monthly payment date",
    trunc(((lp.duration * ((l.amtborrowed/100)/lp.intrate))),2) as "total intrest on loan"
    from bank_customer bc
    left join loan l
    on l.primary = bc.custid
    left join loan_product lp
    on l.loanprodid = lp.loanprodid;
    
    select * from Customer_Loan_Data;

/*---------------------------------------------------*/

create or replace view Customer_CD_Data as
    select 
    bc.Fname || ' ' || bc.lname as "customer name",
    bc.custid as "customer id",
    nvl(cp.descrip, 'no discription availible') as "CD description",
    trunc((sysdate - ca.dateopened)/365,2) as "age of CD years",
    cp.intrate as "cd intrest rate",
    (((ca.cdamt/100) * cp.intrate) * (trunc(((sysdate - ca.dateopened)/365),2))) as "total accured intrest"  
    
    from bank_customer bc
    left join cd_account ca
    on bc.custid = ca.primary
    left join cd_product cp
    on ca.cdprodid = cp.cdprodid
    where ca.cdno is not null
    and cp.duration < trunc((sysdate - ca.dateopened)/365*12,2);

    select * from Customer_CD_Data;

/*---------------------------------------------------*/

create or replace view Manager_Data as
    select 
    be.fname || ' ' || be.lname as "manager name",
    br.b_name as "branch managing",
    bm.empid,
    (select count(*) from bank_employee bep
    where bep.staffmanager = bm.empid) as "number of employees",
    trunc((sysdate - bm.assigndate)/265,2) as "years as manager",
    (select sum(ead.salary) 
    from emp_annual_data ead 
    where ead.empid = be.empid) as "employee overhead"
    from BANK_EMPLOYEE be
    left join branch_manager bm
    on be.empid = bm.empid
    left join branch br
    on bm.branchid = br.branchid
    where be.empid = bm.empid;
    
    select * from Manager_Data;

/*---------------------------------------------------*/

create or replace view Manager_Branch_Data as
    select 
    be.fname || ' ' || be.lname as "manager name",
    br.b_name as "branch managing",
    bm.empid,
    
    nvl((select sum(dt.amount)
    from deposit_acct_transaction dt
    where dt.accessptid = bap.accesspointid), 0) as "total deposited at bm branch",
    
     nvl((select atm.purchprice 
    from atm atm
    where atm.atmid = bap.atmid),0) as "cost of atm at branch",
    
    (select atm.purchdate 
    from atm atm
    where atm.atmid = bap.atmid) as "date atm was purchased",
    
    (select count(*) 
    from car c
    where c.branchid = bm.branchid) as "number of cars at branch",
    
    nvl((select sum(c.purchprice) 
    from car c
    where c.branchid = bm.branchid),0) as "cost of cars at branch"
    
    from branch_manager bm
    left join bank_employee be
    on be.empid = bm.empid
    left join branch_access_points bap 
    on bm.branchid = bap.branchid
    inner join branch br
    on bm.branchid = br.branchid;
    
    select * from Manager_Branch_Data;

/*---------------------------------------------------*/


/*---------------------------------------------------
************* chapter 2 *****************************
---------------------------------------------------*/



    select * from cd_account;
    select * from cd_product;
    
    select * from loan;
    select * from loan_product;
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