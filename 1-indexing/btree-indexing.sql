--1. Thiết kế DB
CREATE DATABASE EmployeeManagement;
GO

USE EmployeeManagement;
GO


CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY, -- Clustered Index mặc định
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Department NVARCHAR(50) NOT NULL, -- cột DEPARTMENT
    HireDate DATE NOT NULL,
    Salary DECIMAL(18, 2) NOT NULL
);

--2. Tạo dữ liệu mẫu lớn (1.000.000 rows)
-- Tăng số lượng dữ liệu lên 500,000 bản ghi
DECLARE @i INT = 1;

WHILE @i <= 500000
BEGIN
    INSERT INTO Employees (EmployeeID, FirstName, LastName, Department, HireDate, Salary)
    VALUES 
    (@i, CONCAT('FirstName', @i), CONCAT('LastName', @i), 
     CASE 
        WHEN @i % 4 = 0 THEN 'IT'
        WHEN @i % 4 = 1 THEN 'HR'
        WHEN @i % 4 = 2 THEN 'Finance'
        ELSE 'Marketing'
     END,
     DATEADD(DAY, -@i, GETDATE()), 
     RAND() * 50000 + 50000);

    SET @i = @i + 1;
END;



--3. Bắt đầu test performance:Tạo Composite Non-Clustered Index

--3.1. Truy vấn kiểm tra hiệu suất: Truy vấn với WHERE và ORDER BY
CREATE NONCLUSTERED INDEX IX_Employees_Department_Salary ON Employees(Department, Salary);

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SELECT * 
FROM Employees
WHERE Department = 'Finance'
ORDER BY Salary DESC;

/*
(24825 rows affected)
Table 'Employees'. Scan count 1, logical reads 1197, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 149 ms.
*/

SELECT * 
FROM Employees
WHERE Department = 'IT';
/*
(24825 rows affected)
Table 'Employees'. Scan count 1, logical reads 1197, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 165 ms.
*/

SELECT * 
FROM Employees
WHERE Department = 'Finance' AND Salary > 70000;
/*

(14950 rows affected)
Table 'Employees'. Scan count 1, logical reads 1197, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 103 ms.
*/

SELECT Department, MAX(Salary) AS MaxSalary, AVG(Salary) AS AvgSalary
FROM Employees
GROUP BY Department;
/*
(4 rows affected)
Table 'Employees'. Scan count 1, logical reads 414, physical reads 0, page server reads 0, read-ahead reads 7, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 19 ms.
*/



DROP INDEX IX_Employees_Department_Salary ON Employees;
SELECT * 
FROM Employees
WHERE Department = 'Finance'
ORDER BY Salary DESC;

/*
(24825 rows affected)
Table 'Employees'. Scan count 1, logical reads 1197, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 153 ms..
*/

SELECT * 
FROM Employees
WHERE Department = 'IT';
/*
(24825 rows affected)
Table 'Employees'. Scan count 1, logical reads 1197, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 16 ms,  elapsed time = 137 ms.
*/

SELECT * 
FROM Employees
WHERE Department = 'Finance' AND Salary > 70000;
/*

(14950 rows affected)
Table 'Employees'. Scan count 1, logical reads 1197, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 91 ms.
*/


SELECT Department, MAX(Salary) AS MaxSalary, AVG(Salary) AS AvgSalary
FROM Employees
GROUP BY Department;
/*
(4 rows affected)
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Employees'. Scan count 1, logical reads 1197, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 16 ms,  elapsed time = 39 ms.
*/
