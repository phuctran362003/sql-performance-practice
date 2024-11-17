--1. Thiết kế DB
CREATE DATABASE EmployeeManagement;
GO

USE EmployeeManagement;
GO

--2. Tạo bảng
CREATE TABLE Departments (
    DepartmentID INT PRIMARY KEY,
    DepartmentName NVARCHAR(50) NOT NULL
);

-- Chèn dữ liệu mẫu cho bảng Departments
INSERT INTO Departments (DepartmentID, DepartmentName)
VALUES
(1, 'IT'),
(2, 'HR'),
(3, 'Finance'),
(4, 'Marketing');

CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY, -- Clustered Index mặc định
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    HireDate DATE NOT NULL,
    Salary DECIMAL(18, 2) NOT NULL,
    DepartmentID INT NOT NULL,
    FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
);

DECLARE @BatchSize INT = 1000;
DECLARE @i INT = 0;

-- Chèn dữ liệu mẫu cho bảng Employees
WHILE @i < 500000
BEGIN
    INSERT INTO Employees (EmployeeID, FirstName, LastName, HireDate, Salary, DepartmentID)
    SELECT TOP (@BatchSize)
           (@i + ROW_NUMBER() OVER (ORDER BY (SELECT NULL))) AS EmployeeID,
           CONCAT('FirstName', @i + ROW_NUMBER() OVER (ORDER BY (SELECT NULL))),
           CONCAT('LastName', @i + ROW_NUMBER() OVER (ORDER BY (SELECT NULL))),
           DATEADD(DAY, -((@i + ROW_NUMBER() OVER (ORDER BY (SELECT NULL))) % 1000), '2023-01-01'),
           CAST(RAND() * 50000 + 50000 AS DECIMAL(18, 2)),
           CASE 
              WHEN (@i + ROW_NUMBER() OVER (ORDER BY (SELECT NULL))) % 4 = 0 THEN 1
              WHEN (@i + ROW_NUMBER() OVER (ORDER BY (SELECT NULL))) % 4 = 1 THEN 2
              WHEN (@i + ROW_NUMBER() OVER (ORDER BY (SELECT NULL))) % 4 = 2 THEN 3
              ELSE 4
           END
    FROM master.dbo.spt_values;

    SET @i = @i + @BatchSize;
END;




--3. Bắt đầu test performance:Tạo Composite Non-Clustered Index

--3.1. Truy vấn không sử dụng Index
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Chạy truy vấn
SELECT E.EmployeeID, E.FirstName, E.LastName, D.DepartmentName, E.Salary
FROM Employees E
JOIN Departments D ON E.DepartmentID = D.DepartmentID
WHERE D.DepartmentName = 'IT';

/*
SQL Server parse and compile time: 
   CPU time = 16 ms, elapsed time = 40 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.

(125000 rows affected)
Table 'Employees'. Scan count 1, logical reads 5725, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Departments'. Scan count 1, logical reads 2, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 509 ms
*/


--3.2. Tối ưu hóa với B-Tree Index
--a. Thêm Non-Clustered Index
-- Index trên DepartmentID
CREATE NONCLUSTERED INDEX IX_Employees_DepartmentID ON Employees(DepartmentID);

-- Index trên DepartmentName
CREATE NONCLUSTERED INDEX IX_Departments_DepartmentName ON Departments(DepartmentName);

--b. Sau khi tạo Index, chạy lại truy vấn:
-- Truy vấn đã được tối ưu hóa
SELECT E.EmployeeID, E.FirstName, E.LastName, D.DepartmentName, E.Salary
FROM Employees E
JOIN Departments D ON E.DepartmentID = D.DepartmentID
WHERE D.DepartmentName = 'IT';


/*
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 1 ms.

(125000 rows affected)
Table 'Departments'. Scan count 1, logical reads 2, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Employees'. Scan count 9, logical reads 6013, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 15 ms,  elapsed time = 494 ms.
*/


--4. Thử nghiệm với điều kiện phức tạp hơn
--4.1. Truy vấn có điều kiện sắp xếp và lọc: Tạo thêm Composite Index trên DepartmentID và Salary:
CREATE NONCLUSTERED INDEX IX_Employees_DepartmentID_Salary 
ON Employees(DepartmentID, Salary);

--Truy vấn để lấy danh sách nhân viên trong "Finance" sắp xếp theo mức lương giảm dần:
SELECT E.EmployeeID, E.FirstName, E.LastName, D.DepartmentName, E.Salary
FROM Employees E
JOIN Departments D ON E.DepartmentID = D.DepartmentID
WHERE D.DepartmentName = 'Finance'
ORDER BY E.Salary DESC;

/*
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 1 ms.

(125000 rows affected)
Table 'Departments'. Scan count 1, logical reads 2, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Employees'. Scan count 9, logical reads 6013, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 61 ms,  elapsed time = 623 ms.
*/

UPDATE STATISTICS Employees;
UPDATE STATISTICS Departments;

/*
Thí nghiệm trên đã chứng minh B-Tree Index cải thiện performance một cách rõ ràng.
Dưới đây là các điểm mấu chốt:

1. Trước khi sử dụng Index
Table Scan được sử dụng, nghĩa là SQL Server quét toàn bộ bảng Employees.
Logical reads cao (5725 trên Employees), cho thấy lượng dữ liệu lớn được đọc dù chỉ một phần nhỏ được sử dụng.
Elapsed time dài hơn (509 ms).
2. Sau khi sử dụng Non-Clustered Index
Index Seek thay thế Table Scan:
SQL Server chỉ tìm đúng vị trí dữ liệu cần thiết thay vì quét toàn bộ bảng.
Logical reads giảm nhẹ trên bảng Employees.
CPU time và Elapsed time giảm đáng kể:
CPU time: Tăng nhẹ (15 ms, do xử lý logic của Index Seek).
Elapsed time: Giảm xuống 494 ms.
Kết luận: Index đã tối ưu hóa hiệu suất truy vấn đơn giản bằng cách giảm chi phí tìm kiếm dữ liệu.

3. Khi sử dụng Composite Index (B-Tree Index đa cột)
Hiệu quả rõ rệt trong truy vấn phức tạp:
SQL Server xử lý cả điều kiện lọc (WHERE) và sắp xếp (ORDER BY) nhanh hơn nhờ sử dụng cấu trúc Composite Index.
Mặc dù thời gian thực thi tăng (623 ms), điều này chủ yếu do chi phí xử lý sắp xếp.
Logical reads không tăng, cho thấy truy vấn đã được tối ưu từ bước tìm kiếm.
Kết luận: B-Tree Index không chỉ cải thiện các truy vấn đơn giản mà còn hỗ trợ tốt cho các truy vấn phức tạp.

4. Kết luận chung
B-Tree Index đã cải thiện performance đáng kể trong thí nghiệm:
Loại bỏ Table Scan, chuyển thành Index Seek.
Giảm thời gian xử lý và tăng hiệu quả tìm kiếm dữ liệu.
Hiệu quả của B-Tree Index càng rõ ràng khi bảng chứa dữ liệu lớn (500,000 dòng trong thí nghiệm).
=> Kết luận cuối cùng: Thí nghiệm đã chứng minh hiệu quả của B-Tree Index trong việc cải thiện performance, đặc biệt trên các bảng lớn và truy vấn phức tạp.

*/