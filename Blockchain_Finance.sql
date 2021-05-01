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
    bc.Fname || ' ' || bc.mname || ' ' || bc.lname as "customer name",
    bc.custid as "customer id",
    l.loanno,
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

/*
a- Create a sequence called ID_generator to be used for Account ID.
Start with 1111
Generate only odd numbers for security
Cache 50 numbers at a time
*/
create sequence ID_generator 
    START WITH     1111
    INCREMENT BY   2
    cache 50;

/*b- Create a sequence to be used for the Transaction ID. (Make your own assumption).*/
create sequence ID_Transaction 
    START WITH      0
    INCREMENT BY    1
    cache           1000
    minvalue        0
    maxvalue        9999999999
    cycle;

/*---------------------------------------------------
************* chapter 3 *****************************
---------------------------------------------------*/
set serveroutput on;

DROP TABLE Transaction_Log;

create table Transaction_Log(
    transferamount      number,
    sendingaccount      char(10),
    recievingaccount    char(10),
    tranactiondatetime  timestamp(6)
);

create or replace procedure transfer_coins(V_amount number, v_send char, v_recieve char)
AS
    v_transferamount      number;
    v_sendingaccount      char(10);
    v_recievingaccount    char(10);
    v_tranactiondatetime  timestamp(6);
    v_fee                 number;    
    V_temp_num            number;

   BEGIN
    if substr(v_send, 0,2) = 'CCR' then
        select balance into v_transferamount from credit_account
        WHERE  CREDITACCTNO = v_send;
        
        if v_transferamount < V_amount then
            RAISE_APPLICATION_ERROR(-20031, 'ACCOUNT: ' || v_send || ' DOES NOT HAVE SUFFICENT FUNDS');
        else
            UPDATE CREDIT_ACCOUNT CA
                SET CA.BALANCE = CA.BALANCE - V_amount
                WHERE CA.CREDITACCTNO = V_SEND;
        END IF;
    else
        select DA.balance, DAP.TRANSFEE into v_temp_num, V_FEE
        from deposit_acct DA
        LEFT JOIN DEPOSIT_ACCT_PRODUCT DAP
        ON DA.ACCTPRODID = DAP.ACCTPRODID
        WHERE ACCTNO = v_send;
        
        v_transferamount:= v_temp_num + V_FEE;
        
        if v_temp_num < V_amount then
            RAISE_APPLICATION_ERROR(-20031, 'ACCOUNT: ' || v_send || ' DOES NOT HAVE SUFFICENT FUNDS');
        else
            UPDATE DEPOSIT_ACCT DA
                SET DA.BALANCE = DA.BALANCE - V_amount
                WHERE DA.ACCTNO = V_SEND;
        END IF;
    end if;

          if substr(V_RECIEVE, 0,2) = 'CCR' then
            UPDATE CREDIT_ACCOUNT CA
                SET CA.BALANCE = CA.BALANCE + V_amount
                WHERE CA.CREDITACCTNO = V_RECIEVE;
          else
            UPDATE DEPOSIT_ACCT dA
                SET DA.BALANCE = DA.BALANCE + V_amount
                WHERE DA.ACCTNO = V_RECIEVE;
          end if;
          
          INSERT INTO Transaction_Log(
                transferamount,
                sendingaccount,
                recievingaccount,
                tranactiondatetime
          ) VALUES (
                V_amount,
                V_SEND,
                v_RECIEVE,
                CURRENT_TIMESTAMP
          );
    
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ONE OF THE ACCOUNTS IS NOT VALID');
   END;
/

EXEC transfer_coins(50, 'CDEP000002', 'CDEP000001');

SELECT * FROM Transaction_Log;
select * from DEPOSIT_ACCt; 

/************************************************************************************/
DROP TABLE B_C_File;
CREATE TABLE B_C_File(
    F_NAME  VARCHAR2(512),
    L_NAME  VARCHAR2(512),
    ADDRESS VARCHAR2(512),
    B_DATE  DATE
);

create or replace PROCEDURE Birthday_sub (
    CURR_DAY IN DATE DEFAULT SYSDATE
)
AS
    V_FNAME    VARCHAR2(512);
    V_LNAME    VARCHAR2(512);
    V_ADDRESS  VARCHAR2(512);
    V_DOB      DATE;
    
    CURSOR C_CUSTOMER IS
    SELECT 
    FNAME,
    LNAME, 
    STREET || ' ' || CITY || ', ' || ZIP ,
    DOB
    FROM BANK_CUSTOMER;
    
BEGIN

Open C_CUSTOMER;

    LOOP 
    
    FETCH C_CUSTOMER 
    INTO V_FNAME, V_LNAME, V_ADDRESS, V_DOB;
    EXIT WHEN C_CUSTOMER%NOTFOUND;    
    
    IF mod(months_between(to_date(sysdate),V_DOB),12)>=11.5 OR  mod(months_between(to_date(sysdate-15),V_DOB),12)>=11.5 THEN
        insert into B_C_File
        values(V_FNAME, V_LNAME, V_ADDRESS, V_DOB);
        DBMS_OUTPUT.PUT_LINE(V_FNAME || ' ' || V_LNAME || ' living at ' || V_ADDRESS || ' was added to the table ');
    END IF;
    
    END LOOP;
    
CLOSE  C_CUSTOMER;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('NO CUSTOMERS HAVE BIRTHDAY NEAR THIS DATE');
        CLOSE  C_CUSTOMER;
    when INVALID_CURSOR then
        DBMS_OUTPUT.PUT_LINE('CURSOR IS INVALID');
 END Birthday_sub;
/

SELECT *
FROM BANK_CUSTOMER;

INSERT INTO BANK_CUSTOMER
values
(
9900000005,
555887725,
'Jimbo',
'Chang',
'Estavez',
to_date('04-20-1993','mm-dd-yyyy'),
'19 Grogan',
'Quincy',
'MA',
02109,
6034344444,
null,
2223456781,
'vnai12*',
'(1i291n^&',
'aovin201',
null
);

update BANK_CUSTOMER
set dob =to_date('05-01-1993','mm-dd-yyyy')
where custid=9900000004;

SELECT *
FROM B_C_File;

EXEC Birthday_sub;

/************************************************************************************/
create table Today_Transaction
(
    date_time           timestamp,
    accountnum          char(10),
    accounttype         varchar2(64),
    amount              number,
    depoist_withdraw    varchar2(16)
);

create or replace procedure Get_Today_Transaction(
    V_Date IN DATE DEFAULT SYSDATE    
)
as
    V_dt            timestamp;
    v_accountnum    char(10);
    v_type          varchar2(64);
    v_amount        number;
    
    cursor C_withdraw is
    select 
    creditacctno,
    transtype,
    transdatetime,
    amount
    from credit_acct_transaction
    where to_char(transdatetime, 'mm-dd-yyyy') = to_char(sysdate, 'mm-dd-yyyy');
    
    cursor C_deposit is
    select 
    acctno,
    transtype,
    transdatetime,
    amount
    from deposit_acct_transaction
    where to_char(transdatetime, 'mm-dd-yyyy') = to_char(sysdate, 'mm-dd-yyyy');
    
begin

Open C_withdraw;

    LOOP 
    
        FETCH C_withdraw 
        INTO v_accountnum, v_type, V_dt, v_amount;
        EXIT WHEN C_withdraw%NOTFOUND;   
        
        IF UPPER(v_type) = 'CREDIT' THEN
            insert into Today_Transaction
            values(
               V_dt,
               v_accountnum,
               v_type,
               v_amount,
               'withdrawl'
            );
        ELSE
            insert into Today_Transaction
            values(
               V_dt,
               v_accountnum,
               v_type,
               v_amount,
               'withdrawl'
            );
        END IF;

    END LOOP;
    
CLOSE  C_withdraw;

Open C_deposit;

    LOOP 
    
        FETCH C_deposit 
        INTO v_accountnum, v_type, V_dt, v_amount;
        EXIT WHEN C_deposit%NOTFOUND;   
        
        IF UPPER(v_type) = 'CREDIT' THEN
            insert into Today_Transaction
            values(
               V_dt,
               v_accountnum,
               v_type,
               v_amount,
               'deposit'
            );
        ELSE
            insert into Today_Transaction
            values(
               V_dt,
               v_accountnum,
               v_type,
               v_amount,
               'deposit'
            );
        END IF;

    END LOOP;
    
CLOSE  C_deposit;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('NO TRANSACTIONS FOUND');
end;
/

exec Get_Today_Transaction;

select * from Today_Transaction;

/************************************************************************************/

create or replace function CustomerInfo(v_custnum char)
return number
is 
    v_total number;
    
begin
   select nvl(da.balance,0) into v_total
    from bank_customer bc
    left join deposit_acct da
    on bc.custid = da.primary
    where bc.custid = v_custnum;
    
    return v_total;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('NO TRANSACTIONS FOUND');
        return null;
    IF SQL%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('no record found for ' || v_custnum);
        return null;
    end if;
end;
/

select CustomerInfo(9900000001) from dual;

/************************************************************************************/

create or replace function CustomerInfo(v_custnum number, v_date date)
return number
is 
    v_total number;
    
begin

    select nvl(sum(dat.amount),0) into v_total
    from bank_customer bc
    left join deposit_acct da
    on bc.custid = da.primary
    left join deposit_acct_transaction dat
    on da.acctno = dat.acctno
    where bc.custid = v_custnum 
    and to_char(transdatetime, 'mm-dd-yyyy') = to_char(v_date, 'mm-dd-yyyy') ;
    
    return v_total;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('NO TRANSACTIONS FOUND');
        return null;
    IF SQL%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('no record found for ' || v_custnum);
        return null;
    end if;
end;
/

select CustomerInfo(9900000001, '02-DEC-19') from dual;

/************************************************************************************/

create or replace function CustomerInfo(v_custnum number, v_date date, v_coowner number)
return number
is 
    v_total number;
begin

   select nvl(sum(dat.amount),0) into v_total
    from bank_customer bc
    left join deposit_acct da
    on bc.custid = da.primary
    left join deposit_acct_transaction dat
    on da.acctno = dat.acctno
    where bc.custid = v_custnum
    and da.coowner = v_coowner
    and to_char(transdatetime, 'mm-dd-yyyy') = to_char(v_date, 'mm-dd-yyyy');
    
    return v_total;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('NO TRANSACTIONS FOUND');
        return null;
    IF SQL%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('no record found for ' || v_custnum);
        return null;
    end if;
end;
/

select CustomerInfo(9900000001, '02-DEC-19', 9900000003) from dual;

/************************************************************************************/

create or replace procedure Last_Ten_Transaction(V_Cust number)
as

    cursor C_transactions is
    select 
    dat.transtype,
    dat.transdatetime,
    dat.amount
    from bank_customer bc
    left join deposit_acct da
    on bc.custid = da.primary
    left join deposit_acct_transaction dat
    on da.acctno = dat.acctno
    where bc.custid = V_Cust
    
    union
    
    select 
    cat.transtype,
    cat.transdatetime,
    cat.amount
    from bank_customer bc
    left join credit_account da
    on bc.custid = da.primary
    left join credit_acct_transaction cat
    on da.creditacctno = cat.creditacctno
    where bc.custid = V_Cust;

    V_counter       number;
    V_type          varchar2(16);
    v_transdatetime timestamp;
    V_amount        number;
    
begin
    
    Open C_transactions;

    LOOP 
    
        FETCH C_transactions 
        INTO V_type, v_transdatetime, V_amount;
        EXIT WHEN C_transactions%NOTFOUND or V_counter = 10;
        
        DBMS_OUTPUT.PUT_LINE(V_type || ' '  || v_transdatetime || ' ' || V_amount);
        
        V_counter:= V_counter + 1;
        
   END LOOP;
    
CLOSE  C_transactions;       
        
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('NO TRANSACTIONS FOUND');
    IF SQL%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('no record found for ' || v_cust);
    end if;
end;
/

exec Last_Ten_Transaction(9900000001);
    
/************************************************************************************/
create or replace procedure P_Customer_Loan(V_cust number)
as
    V_Customer_name     varchar2(512);
    V_Lno               varchar2(512);
    V_amount            number;

    cursor C_CustLoan is
    select "customer name", loanno, "amount borrowed"
    from Customer_Loan_Data
    where "customer id" = V_cust;
    
BEGIN
    Open C_CustLoan;

        LOOP 
        
            FETCH C_CustLoan 
            INTO V_Customer_name, V_Lno, V_amount;
            EXIT WHEN C_CustLoan%NOTFOUND;
            
            DBMS_OUTPUT.PUT_LINE(V_Customer_name || ' ' || V_Lno || ' ' || V_amount);
            
       END LOOP;
    
    CLOSE  C_CustLoan;       
        
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('NO TRANSACTIONS FOUND');
    IF SQL%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('no record found for ' || v_cust);
    end if;
end;
/

exec P_Customer_Loan(9900000001);

select "customer name", loanno, "amount borrowed" from Customer_Loan_Data;

/************************************************************************************/
drop table Emp_list;
create table Emp_list
(
    full_name       varchar2(512),
    address         varchar2(512),
    b_date          date,
    payrate         number
);

create or replace procedure Old_employees
as

    cursor C_emp is
    select 
    be.fname || ' ' || be.mname || ' ' || be.lname,
    be.street || ' ' || be.city || ', ' || be.state,
    be.dob,
    (select ead.salary
    from emp_annual_data ead
    where ead.empid = be.empid
    and rownum = 1 and ead.year = (select max(e.year)
                                    from emp_annual_data e))
    from bank_employee be;
    
    V_name          varchar2(512);
    v_address       varchar2(512);
    v_dob           date;
    v_pay           number;
    v_temp          number;
    
Begin
    Open C_emp;

        LOOP 
        
            FETCH C_emp 
            INTO V_name, v_address, v_dob, v_pay;
            v_temp:=TRUNC(MONTHS_BETWEEN(SYSDATE, v_dob))/12;
            EXIT WHEN C_emp%NOTFOUND;
            
            if  v_temp > 30 then
                insert into Emp_list
                values(V_name, v_address, v_dob, v_pay);
            end if;
            
       END LOOP;
    
    CLOSE  C_emp;       
        
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('NO employees found FOUND');
    IF SQL%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('no records found');
    end if;
end;
/

exec Old_employees;

/*---------------------------------------------------
************* chapter 4 *****************************
---------------------------------------------------*/

create or replace package BankP is

function current_balance(V_id number, V_type varchar2) return number;

function Last_checking_deposit(V_id number) return varchar2;

function Last_savings_deposit(V_id number) return varchar2;

function last_withdraw_checking(V_id number) return varchar2;

function last_withdraw_savings(V_id number) return varchar2;

end BankP;
/

----------------------------------------------------------------

create or replace package body BankP is

function current_balance(V_id number, v_type varchar2) return number
is
    V_total     number;
begin
    
    if upper(v_type) = upper('credit') then
        select balance into v_total
        from credit_account
        where primary = V_id;
        return v_total;
        
    elsif upper(v_type) = upper('deposit') then
        select balance into v_total
        from DEPOSIT_ACCt
        where primary = V_id;
        return v_total;
        
    else
        RAISE_APPLICATION_ERROR(-20231, v_type || ' is an invalid account type');
        return 0;
    end if; 
EXCEPTION
    WHEN	 VALUE_ERROR THEN					
        DBMS_OUTPUT.PUT_LINE('Error '||SQLCODE||
        SUBSTR(SQLERRM,1,80));  
        return 0;
    WHEN ZERO_DIVIDE THEN
        DBMS_OUTPUT.PUT_LINE('Divide by zero');
        return 0;
    WHEN OTHERS THEN
    IF SQL%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('No such record was found');
        return 0;
    END IF;
        DBMS_OUTPUT.PUT_LINE('Error '||SQLCODE || 
        SUBSTR(SQLERRM,1,80));  
        return 0;
        
end current_balance;

function Last_checking_deposit(V_id number) return varchar2
is

    V_last      varchar2(1024);

begin

 select to_char(cat.transid) || ' ' || to_char(cat.acctno) || ' ' || cat.transtype || ' ' || to_char(cat.transdatetime) || ' ' || to_char(cat.amount) || ' ' || cat.description into V_last
    from deposit_acct_transaction cat
    where cat.acctno = (select acctno from credit_account where primary = V_id)
    and cat.description like '%deposit'
    and cat.transtype like 'Credit'
    and rownum = 1
    order by cat.transdatetime desc;
    
    if v_last is null then 
        RAISE_APPLICATION_ERROR(-20231, V_id || ' account found associated with this customer');
        return null;
    end if; 
    return V_last;
EXCEPTION
    WHEN VALUE_ERROR THEN					
        DBMS_OUTPUT.PUT_LINE('Error '||SQLCODE||
        SUBSTR(SQLERRM,1,80));  
        return null;
    WHEN OTHERS THEN
    IF SQL%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('No such record was found');
        return null;
    END IF;
        DBMS_OUTPUT.PUT_LINE('Error '||SQLCODE || 
        SUBSTR(SQLERRM,1,80));  
        return null;
end Last_checking_deposit;

-----------------------------------------------------

function Last_savings_deposit(V_id number) return varchar2
is

    V_last      varchar2(1024);

begin

 select to_char(cat.transid) || ' ' || to_char(cat.acctno) || ' ' || cat.transtype || ' ' || to_char(cat.transdatetime) || ' ' || to_char(cat.amount) || ' ' || cat.description into V_last
    from deposit_acct_transaction cat
    where cat.acctno = (select acctno from credit_account where primary = V_id)
    and cat.description like '%deposit'
    and cat.transtype like 'Debit'
    and rownum = 1
    order by cat.transdatetime desc;
    
    if v_last is null then 
        RAISE_APPLICATION_ERROR(-20231, V_id || ' account found associated with this customer');
        return null;
    end if; 
    return V_last;
EXCEPTION
    WHEN VALUE_ERROR THEN					
        DBMS_OUTPUT.PUT_LINE('Error '||SQLCODE||
        SUBSTR(SQLERRM,1,80));  
        return null;
    WHEN OTHERS THEN
    IF SQL%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('No such record was found');
        return null;
    END IF;
        DBMS_OUTPUT.PUT_LINE('Error '||SQLCODE || 
        SUBSTR(SQLERRM,1,80));  
        return null;
end Last_savings_deposit;

---------------------------------------------------------

function last_withdraw_checking(V_id number) return varchar2
is

    V_last      varchar2(1024);

begin

 select to_char(cat.transid) || ' ' || to_char(cat.acctno) || ' ' || cat.transtype || ' ' || to_char(cat.transdatetime) || ' ' || to_char(cat.amount) || ' ' || cat.description into V_last
    from deposit_acct_transaction cat
    where cat.acctno = (select acctno from credit_account where primary = V_id)
    and cat.description like '%withdrawal'
    and cat.transtype like 'Credit'
    and rownum = 1
    order by cat.transdatetime desc;
    
    if v_last is null then 
        RAISE_APPLICATION_ERROR(-20231, V_id || ' account found associated with this customer');
        return null;
    end if; 
    return V_last;
EXCEPTION
    WHEN VALUE_ERROR THEN					
        DBMS_OUTPUT.PUT_LINE('Error '||SQLCODE||
        SUBSTR(SQLERRM,1,80));  
        return null;
    WHEN OTHERS THEN
    IF SQL%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('No such record was found');
        return null;
    END IF;
        DBMS_OUTPUT.PUT_LINE('Error '||SQLCODE || 
        SUBSTR(SQLERRM,1,80));  
        return null;
end last_withdraw_checking;

---------------------------------------------------------

function last_withdraw_savings(V_id number) return varchar2
is

    V_last      varchar2(1024);

begin

 select to_char(cat.transid) || ' ' || to_char(cat.acctno) || ' ' || cat.transtype || ' ' || to_char(cat.transdatetime) || ' ' || to_char(cat.amount) || ' ' || cat.description into V_last
    from deposit_acct_transaction cat
    where cat.acctno = (select acctno from credit_account where primary = V_id)
    and cat.description like '%withdrawal'
    and cat.transtype like 'Debit'
    and rownum = 1
    order by cat.transdatetime desc;
    
    if v_last is null then 
        RAISE_APPLICATION_ERROR(-20231, V_id || ' account found associated with this customer');
        return null;
    end if; 
    return V_last;
EXCEPTION
    WHEN VALUE_ERROR THEN					
        DBMS_OUTPUT.PUT_LINE('Error '||SQLCODE||
        SUBSTR(SQLERRM,1,80));  
        return null;
    WHEN OTHERS THEN
    IF SQL%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('No such record was found');
        return null;
    END IF;
        DBMS_OUTPUT.PUT_LINE('Error '||SQLCODE || 
        SUBSTR(SQLERRM,1,80));  
        return null;
end last_withdraw_savings;


end BankP;
/

select BankP.current_balance(9900000001, 'CREDIT') from dual;
select BankP.Last_checking_deposit(9900000001) from dual;
select BankP.Last_savings_deposit(9900000002) from dual;
select BankP.last_withdraw_checking(9900000001) from dual;
select BankP.last_withdraw_savings(9900000001) from dual;


/*---------------------------------------------------
************* chapter 4.B *****************************
---------------------------------------------------*/

create or replace package BranchP is

function branch_address(V_Bid number) return varchar2;
function branch_phone(V_Bid number) return number;
procedure branch_employees(V_Bid number);

end BranchP ;
/

---------------------------------------

create or replace package body BranchP is

function branch_address(V_Bid number) return varchar2
as
    v_address   varchar2(512);
begin
    select br.B_st || ', ' || br.B_city || ', ' || br.B_state || ' ' || br.B_zip into v_address
    from branch br
    where br.branchid = v_bid;
    
    if v_address is null then 
        RAISE_APPLICATION_ERROR(-20231, V_Bid || ' no branch found associated with this number');
        return null;
    end if; 
    return v_address;
EXCEPTION
    WHEN VALUE_ERROR THEN					
        DBMS_OUTPUT.PUT_LINE('Error '||SQLCODE||
        SUBSTR(SQLERRM,1,80));  
        return null;
    WHEN OTHERS THEN
    IF SQL%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('No such record was found');
        return null;
    END IF;
        DBMS_OUTPUT.PUT_LINE('Error '||SQLCODE || 
        SUBSTR(SQLERRM,1,80));  
        return null;
end branch_address;

function branch_phone(V_Bid number) return number
as
    v_phone   varchar2(512);
begin
    select br.branchphone into v_phone
    from branch br
    where br.branchid = v_bid;
    
    if v_phone is null then 
        RAISE_APPLICATION_ERROR(-20231, V_Bid || ' no branch found associated with this number');
        return 0;
    end if; 
    return v_phone;
EXCEPTION
    WHEN VALUE_ERROR THEN					
        DBMS_OUTPUT.PUT_LINE('Error '||SQLCODE||
        SUBSTR(SQLERRM,1,80));  
        return 0;
    WHEN OTHERS THEN
    IF SQL%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('No such record was found');
        return 0;
    END IF;
        DBMS_OUTPUT.PUT_LINE('Error '||SQLCODE || 
        SUBSTR(SQLERRM,1,80));  
        return 0;
end branch_phone;

procedure branch_employees(V_Bid in number)
is
    v_name      varchar2(512);
    
    cursor C_banchemp is
    select be.fname || ' ' || be.mname || ' ' || be.lname
    from bank_employee be
    left join branch_employee bem
    on be.empid = bem.empid
    where be.empid = bem.empid
    and bem.branchid = v_bid;
    
begin
      Open C_banchemp;

        LOOP 
        
            FETCH C_banchemp 
            INTO V_name;
            EXIT WHEN C_banchemp%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE(V_name); 
        end loop;
        
    close C_banchemp;
EXCEPTION
    WHEN VALUE_ERROR THEN					
        DBMS_OUTPUT.PUT_LINE('Error '||SQLCODE||
        SUBSTR(SQLERRM,1,80));  
    WHEN OTHERS THEN
    IF SQL%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('No such record was found');
    END IF;
        DBMS_OUTPUT.PUT_LINE('Error '||SQLCODE || 
        SUBSTR(SQLERRM,1,80));  
end branch_employees;

end BranchP;
/

select BranchP.branch_address(1004) from dual;
select BranchP.branch_phone(1003) from dual;
exec BranchP.branch_employees(1001);

/*---------------------------------------------------
************* chapter 4.C *****************************
---------------------------------------------------*/
create or replace package Insert_pkg  is
    procedure P_insert_customer(
        V_ssn    in   char,
        v_fname  in   varchar2,
        v_mname  in   varchar2,
        v_lname  in   varchar2,
        v_dob    in   date,
        v_street in   varchar2,
        v_city   in   varchar2,
        v_state  in   varchar2,
        v_zip    in   number,
        v_homePhone in char,
        v_workPhone in char,
        v_atmno  in   char,
        V_atmpw  in   varchar2,
        v_web    in   varchar2,
        v_webp   in   varchar2,
        v_email  in   varchar2
    );
        
    procedure P_insert_employee(
        V_ssn    in   char,
        v_fname  in   varchar2,
        v_mname  in   varchar2,
        v_lname  in   varchar2,
        v_street in   varchar2,
        v_city   in   varchar2,
        v_state  in   varchar2,
        v_zip    in   number,
        v_homePhone in char,
        v_email  in   varchar2,
        V_gender in   char,
        v_race   in   char,
        v_dob   in    date,
        v_spouse in   varchar2,
        v_spouselname in varchar2,
        V_degree    in  varchar2,
        v_degreedate in date,
        v_hiredate  in date,
         v_job     in varchar2,
        v_number in number       
        );
        
        procedure insert_into_cd(
            v_no        in  char,
            V_prodid    in  varchar2,
            V_prime     in  number,
            V_co        in  number,
            V_amount    in  number
        );
        
        PROCEDURE INSERT_DRIVER(
            v_ID    IN  NUMBER,
            V_LNO   IN VARCHAR2,
            V_STATE IN CHAR,
            V_EXP   IN DATE
        );
        
        procedure delete_driver(
            v_id    in  number
        );
            
end Insert_pkg ;
/
-------------------------------------------------------
create or replace package body Insert_pkg  is

    procedure P_insert_customer(
        V_ssn    in   char,
        v_fname  in   varchar2,
        v_mname  in   varchar2,
        v_lname  in   varchar2,
        v_dob    in   date,
        v_street in   varchar2,
        v_city   in   varchar2,
        v_state  in   varchar2,
        v_zip    in   number,
        v_homePhone in char,
        v_workPhone in char,
        v_atmno  in   char,
        V_atmpw  in   varchar2,
        v_web    in   varchar2,
        v_webp   in   varchar2,
        v_email  in   varchar2
    )
    is
begin
        
        insert into bank_customer
        values(
        ID_generator.nextval,
        V_ssn,
        v_fname,
        v_mname,
        v_lname,
        v_dob,
        v_street,
        v_city,
        v_state,
        v_zip,
        v_homePhone,
        v_workPhone,
        v_atmno,
        V_atmpw,
        v_web,
        v_webp,
        v_email);
        
        exception
         when dup_val_on_index then
          dbms_output.put_line('duplicate values cannot be insert:' || sqlerrm);
    end P_insert_customer;
-----------------------------------------------------------  
     procedure P_insert_employee(
        V_ssn    in   char,
        v_fname  in   varchar2,
        v_mname  in   varchar2,
        v_lname  in   varchar2,
        v_street in   varchar2,
        v_city   in   varchar2,
        v_state  in   varchar2,
        v_zip    in   number,
        v_homePhone in char,
        v_email  in   varchar2,
        V_gender in   char,
        v_race   in   char,
        v_dob   in    date,
        v_spouse in   varchar2,
        v_spouselname in varchar2,
        V_degree    in  varchar2,
        v_degreedate in date,
        v_hiredate  in date,
        v_job     in varchar2,
        v_number  in number      
        )
        is
    begin
    
    insert into bank_employee
        values(
        ID_generator.nextval,
        V_ssn,
        v_fname,
        v_mname,
        v_lname,
        v_street,
        v_city,
        v_state,
        v_zip,
        v_homePhone,
        v_email,
        V_gender,
        v_race,
        v_dob,
        v_spouse,
        v_spouselname,
        V_degree,
        v_degreedate,
        v_hiredate,
        v_job,
        v_number        
        );
        exception
        when dup_val_on_index then
          dbms_output.put_line('duplicate values cannot be insert:');
    end P_insert_employee;
 -------------------------------------------------------   
    procedure insert_into_cd(
            v_no        in  char,
            V_prodid    in  varchar2,
            V_prime     in  number,
            V_co        in  number,
            V_amount    in  number
        )
    is
    v_min   number;    
    begin
    
    select mincdamt into v_min
    from cd_product
    where cdprodid = v_prodid;
    
    if v_amount < v_min then
        RAISE_APPLICATION_ERROR(-20035, 'CD TYPE: ' || v_prodid || ' HAS A MINIMUM OF ' || V_MIN);
    ELSE
        INSERT INTO CD_ACCOUNT
        VALUES(
            V_NO,
            V_prodid,
            SYSDATE,
            V_PRIME,
            V_CO,
            v_AMOUNT);
    END IF;
    exception
        when dup_val_on_index then
          dbms_output.put_line('duplicate values cannot be insert:');
          
    end insert_into_cd;
---------------------------------------------------------
  PROCEDURE INSERT_DRIVER(
            v_ID    IN  NUMBER,
            V_LNO   IN VARCHAR2,
            V_STATE IN CHAR,
            V_EXP   IN DATE
        )
  IS
    V_EMP       NUMBER;
  BEGIN
v
        INSERT INTO driver
        VALUES(
            V_ID,
            V_LNO,
            v_STATE,
            V_EXP);
    ELSE 
        RAISE_APPLICATION_ERROR(-20535, 'NO EMPLOYEE FOUND WITH ID: ' || v_ID);
    END IF;
    exception
        when dup_val_on_index then
          dbms_output.put_line('duplicate values cannot be insert:');
  end INSERT_DRIVER;
---------------------------------------------------
    procedure delete_driver(
            v_id    in  number
        )
    is
    v_emp   number;
    begin
      SELECT EMPID INTO V_EMP
      FROM driver
      WHERE empid = v_ID;
    IF V_EMP IS NOT NULL THEN
        delete from driver
        where empid=v_id;
    else
        RAISE_APPLICATION_ERROR(-20535, 'NO EMPLOYEE FOUND WITH ID: ' || v_ID);
    end if;
    EXCEPTION 
   WHEN ZERO_DIVIDE THEN  
      dbms_output.put_line('MATHMATICAL ERROR');

   WHEN OTHERS THEN  
      dbms_output.put_line('Some other kind of error occurred when deleting');

end Insert_pkg ;
/

set serveroutput on;

exec Insert_pkg.P_insert_customer(008293564,'Jorge','Xi','Usman', to_date('06-20-1969','mm-dd-yyyy'), '55 Copley', 'Boston', 'MA', 02129, 6034344444, 6173380932, 2003456781, 'vdamn)*(', '(1i2.,#^&', 'Pkwvin201', 'GWag@swag.biz');
exec Insert_pkg.P_insert_employee(003001234,'chuck','theiceman','liddel','venturas ave','Las Vegas','nv','67238',9876451726,'ice@gmail.com','m','w',to_date('06-20-1969','mm-dd-yyyy'),'susan','liddel','bach',to_date('06-20-1989','mm-dd-yyyy'),to_date('06-20-1999','mm-dd-yyyy'),'security',1000000002);
EXEC Insert_pkg.insert_into_cd('CCD0000004', 'CD3', '9900000003', '9900000001',4500);
EXEC Insert_pkg.INSERT_DRIVER(1000000009, 'NH41LN021', 'NH', '04-APR-22');

/*****************************************************************/

select * from credit_acct_transaction;
select * from deposit_acct_transaction cp;

    select * from cd_account;
    select * from cd_product;
    select * from driver;
    
    select * from loan;
    select * from loan_product;
    select * from EMP_ANNUAL_DATA;
    select * from bank_employee;
    select * from branch_employee;
    select * from CREDIT_ACCT_TRAnSACTION;
    select * from DEPOSIT_ACCT_TRANSACTION;
    select * from DEPOSIT_ACCt; 
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