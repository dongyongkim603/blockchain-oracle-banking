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

create view Employee_salary as;
    
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
    
    (select sum(nvl(g.salary,0))
    from EMP_ANNUAL_DATA g
    where g.empid = b.empid and b.branchid = e.empid) as "total salary at branch"
    
    from bank_employee e
    left join branch_employee b
    on e.empid = b.empid;
    
/*---------------------------------------------------*/
    
    select * from EMP_ANNUAL_DATA;
    select * from bank_employee;
    select * from branch;
    select * from branch_employee;