create view EMPLOYEE_DATA as;

    select 
    b.fname || ' ' || b.mname || ' ' || b.lname as "name of employee",
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
    
    b.hiredate as "Date employee was hired",
    b.dob as "birth date",
    trunc(((sysdate - b.dob)/365.25),0) as "age",
    br.phoneext as "branch phone extension",
    (select e.branchphone
    from branch e
    where e.branchid = br.branchid) as "phone number"
    
    from Bank_employee b
    inner join EMP_ANNUAL_DATA a
    on b.empid = a.empid
    inner join branch_employee br
    on br.empid = b.empid;
    
    
        
--*********************************************************

    select * from BRANCH_EMPLOYEE;
    select * from BRANCH;
    
    select c.salary 
    from EMP_ANNUAL_DATA c
    where c.year <= to_char(sysdate, 'YYYY')
    and c.empid = b.empid
    and rownum = 1
    order by c.year desc
    
    select c.salary 
    from EMP_ANNUAL_DATA c
    where c.year <= to_char(sysdate, 'YYYY')
    and c.empid = 1000000001
    and rownum = 1
    order by c.year desc;