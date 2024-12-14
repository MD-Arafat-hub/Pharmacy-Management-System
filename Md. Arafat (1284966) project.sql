USE master
GO
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Pharmacy_Management')
BEGIN
    DROP DATABASE Pharmacy_Management;
END
GO

Create Database Pharmacy_Management
on
(
	Name='Pharmacy_Management_Data_1',
	FileName='C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\Pharmacy_Management_Data_1.mdf',
	Size=25mb,
	MaxSize=100mb,
	FileGrowth=5%
)
log on
(
	Name='Pharmacy_Management_log_1',
	FileName='C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\Pharmacy_Management_log_1.ldf',
	Size=2mb,
	MaxSize=50mb,
	FileGrowth=1%
);
GO

USE Pharmacy_Management 
GO

-- Create Patients table
CREATE TABLE Patients (
    PatientID INT PRIMARY KEY IDENTITY(1,1),
    Name VARCHAR(100) NOT NULL,
    Age INT,
    Gender VARCHAR(10),
    Contact VARCHAR(15),
    Address VARCHAR(255)
);
GO

-- Create Doctors table
CREATE TABLE Doctors (
    DoctorID INT PRIMARY KEY IDENTITY(1,1),
    Name VARCHAR(100) NOT NULL,
    Specialty VARCHAR(50),
    Contact VARCHAR(15),
    Address VARCHAR(255)
);
GO

-- Create Medications table
CREATE TABLE Medications (
    MedicationID INT PRIMARY KEY IDENTITY(1,1),
    Name VARCHAR(100) NOT NULL,
    Description TEXT,
    Price DECIMAL(10, 2),
    StockQuantity INT
);
GO

-- Create Prescriptions table
CREATE TABLE Prescriptions (
    PrescriptionID INT PRIMARY KEY IDENTITY(1,1),
    PatientID INT,
    DoctorID INT,
    Date DATE,
    Notes TEXT,
    FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
    FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID)
);
GO

-- Create PrescriptionDetails table
CREATE TABLE PrescriptionDetails (
    PrescriptionDetailID INT PRIMARY KEY IDENTITY(1,1),
    PrescriptionID INT,
    MedicationID INT,
    Quantity INT,
    Dosage VARCHAR(50),
    FOREIGN KEY (PrescriptionID) REFERENCES Prescriptions(PrescriptionID),
    FOREIGN KEY (MedicationID) REFERENCES Medications(MedicationID)
);
GO

-- Create Sales table
CREATE TABLE Sales (
    SaleID INT PRIMARY KEY IDENTITY(1,1),
    MedicationID INT,
    SaleDate DATE,
    Quantity INT,
    TotalPrice DECIMAL(10, 2),
    FOREIGN KEY (MedicationID) REFERENCES Medications(MedicationID)
);
GO

-- Insert into Patients table
INSERT INTO Patients (Name, Age, Gender, Contact, Address) VALUES
('Kabbo', 35, 'Female', '1234567890', 'Mirpur-11'),
('Rukaiya', 28, 'Female', '0987654321', 'Farmgate'),
('Rabbi', 50, 'Male', '1112223333', 'Dhanmondi');
GO

-- Insert into Doctors table
INSERT INTO Doctors (Name, Specialty, Contact, Address) VALUES
('Dr. Samaul', 'Cardiology', '2223334444', 'Farmgate'),
('Dr. Arafat Rahman', 'Dermatology', '5556667777', 'Shawrapara'),
('Dr. Arafat', 'Pediatrics', '8889990000', 'Mirhajirbagh');
GO

-- Insert into Medications table
INSERT INTO Medications (Name, Description, Price, StockQuantity) VALUES
('Aspirin', 'Pain reliever and fever reducer', 10.50, 200),
('Amoxicillin', 'Antibiotic', 25.00, 150),
('Lisinopril', 'Blood pressure medication', 15.75, 100);
GO

-- Insert into Prescriptions table
INSERT INTO Prescriptions (PatientID, DoctorID, Date, Notes) VALUES
(1, 1, '2024-08-01', 'Take as needed for chest pain'),
(2, 2, '2024-08-05', 'Apply twice daily to affected area'),
(3, 3, '2024-08-10', 'Take one tablet daily in the morning');
GO

-- Insert into PrescriptionDetails table
INSERT INTO PrescriptionDetails (PrescriptionID, MedicationID, Quantity, Dosage) VALUES
(1, 1, 30, '500mg'),
(2, 2, 15, '250mg'),
(3, 3, 60, '10mg');
GO

-- Insert into Sales table
INSERT INTO Sales (MedicationID, SaleDate, Quantity, TotalPrice) VALUES
(1, '2024-08-15', 2, 21.00),
(2, '2024-08-16', 1, 25.00),
(3, '2024-08-17', 3, 47.25);
GO

--storeprocedure add anew prescription
CREATE PROCEDURE AddNewPrescription
    @PatientID INT,
    @DoctorID INT,
    @Date DATE,
    @Notes NVARCHAR(MAX),
    @MedicationID INT,
    @Quantity INT,
    @Dosage NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @NewPrescriptionID INT;

    -- Insert into Prescriptions table
    INSERT INTO Prescriptions (PatientID, DoctorID, Date, Notes)
    VALUES (@PatientID, @DoctorID, @Date, @Notes);

    -- Get the last inserted PrescriptionID
    SET @NewPrescriptionID = SCOPE_IDENTITY();

    -- Insert into PrescriptionDetails table
    INSERT INTO PrescriptionDetails (PrescriptionID, MedicationID, Quantity, Dosage)
    VALUES (@NewPrescriptionID, @MedicationID, @Quantity, @Dosage);
END;
GO

EXEC AddNewPrescription
    @PatientID = 1, 
    @DoctorID = 2, 
    @Date = '2024-08-18',
    @Notes = 'Take as prescribed.',
    @MedicationID = 1,
    @Quantity = 30,
    @Dosage = '500mg';
GO

--MedicationChangesLog table
CREATE TABLE MedicationChangesLog (
    LogID INT PRIMARY KEY IDENTITY(1,1),
    MedicationID INT,
    ChangeType NVARCHAR(10),
    ChangeDate DATETIME DEFAULT GETDATE(),
    OldQuantity INT,
    NewQuantity INT
);
GO

--trigger with trg_MedicationChanges
CREATE TRIGGER trg_MedicationChanges
ON Medications
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Handle INSERT
    IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO MedicationChangesLog (MedicationID, ChangeType, NewQuantity)
        SELECT i.MedicationID, 'INSERT', i.StockQuantity
        FROM inserted i;
    END

    -- Handle DELETE
    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO MedicationChangesLog (MedicationID, ChangeType, OldQuantity)
        SELECT d.MedicationID, 'DELETE', d.StockQuantity
        FROM deleted d;
    END

    -- Handle UPDATE
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO MedicationChangesLog (MedicationID, ChangeType, OldQuantity, NewQuantity)
        SELECT d.MedicationID, 'UPDATE', d.StockQuantity, i.StockQuantity
        FROM deleted d
        INNER JOIN inserted i ON d.MedicationID = i.MedicationID;
    END
END;
GO

SELECT * FROM MedicationChangesLog;
GO

--Scalar Function with CalculateTotalPrice
CREATE FUNCTION CalculateTotalPrice (
    @Price DECIMAL(10, 2),
    @Quantity INT
)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    RETURN @Price * @Quantity;
END;
GO

SELECT dbo.CalculateTotalPrice(15.75, 10) AS TotalPrice;
GO

--Table function with GetLowStockMedications
CREATE FUNCTION GetLowStockMedications (
    @Threshold INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT MedicationID, Name, StockQuantity
    FROM Medications
    WHERE StockQuantity < @Threshold
);
GO

SELECT * FROM dbo.GetLowStockMedications(50);
GO

--Multi statement table function GetPatientPrescriptions
CREATE FUNCTION GetPatientPrescriptions (
    @PatientID INT
)
RETURNS @PrescriptionsTable TABLE
(
    PrescriptionID INT,
    MedicationName VARCHAR(100),
    Quantity INT,
    Dosage VARCHAR(50),
    Date DATE
)
AS
BEGIN
    INSERT INTO @PrescriptionsTable
    SELECT p.PrescriptionID, m.Name, pd.Quantity, pd.Dosage, p.Date
    FROM Prescriptions p
    INNER JOIN PrescriptionDetails pd ON p.PrescriptionID = pd.PrescriptionID
    INNER JOIN Medications m ON pd.MedicationID = m.MedicationID
    WHERE p.PatientID = @PatientID;

    RETURN;
END;
GO

SELECT * FROM dbo.GetPatientPrescriptions(1);
GO

--View with encryption EncryptedPatientView
CREATE VIEW EncryptedPatientView
WITH ENCRYPTION
AS
SELECT PatientID, Name, Age, Gender, Contact
FROM Patients;
GO

--View with Schemabinding MedicationView
CREATE VIEW MedicationView
WITH SCHEMABINDING
AS
SELECT MedicationID, Name, Price, StockQuantity
FROM dbo.Medications;
GO

--View with Both Encryption and SCHEMABINDING 
CREATE VIEW EncryptedBoundPrescriptionView
WITH ENCRYPTION, SCHEMABINDING
AS
SELECT p.PrescriptionID, p.Date, d.Name AS DoctorName, pt.Name AS PatientName
FROM dbo.Prescriptions p
INNER JOIN dbo.Doctors d ON p.DoctorID = d.DoctorID
INNER JOIN dbo.Patients pt ON p.PatientID = pt.PatientID;
GO

SELECT * FROM EncryptedPatientView;
SELECT * FROM MedicationView;
SELECT * FROM EncryptedBoundPrescriptionView;
GO

-- Create a non-clustered index on the Name column
CREATE NONCLUSTERED INDEX IX_PatientName
ON Patients (Name);
GO

--Query Using Subquery
SELECT Name
FROM Patients
WHERE PatientID IN (
    SELECT DISTINCT PatientID
    FROM Prescriptions
);
GO

-- CTE to get patients with their prescriptions
WITH PatientPrescriptions AS (
    SELECT
        p.PatientID,
        p.Name AS PatientName,
        p.Age,
        p.Gender,
        p.Contact,
        p.Address,
        pr.PrescriptionID,
        pr.Date AS PrescriptionDate,
        pr.Notes
    FROM
        Patients p
    JOIN
        Prescriptions pr ON p.PatientID = pr.PatientID
)
-- Query using the CTE
SELECT
    PatientID,
    PatientName,
    Age,
    Gender,
    Contact,
    Address,
    PrescriptionID,
    PrescriptionDate,
    Notes
FROM
    PatientPrescriptions
ORDER BY
    PatientID, PrescriptionDate;
GO

-- Query to get patient names with their prescriptions
SELECT
    p.Name AS PatientName,
    pr.Date AS PrescriptionDate,
    pr.Notes
FROM
    Patients p
JOIN
    Prescriptions pr ON p.PatientID = pr.PatientID
ORDER BY
    p.Name, pr.Date;
GO

--Total Stock Quantity of Medications
SELECT SUM(StockQuantity) AS TotalStock
FROM Medications;
GO

--Average Price of Medications
SELECT AVG(Price) AS AveragePrice
FROM Medications;
GO

--Total Sales Amount for Each Medication
SELECT MedicationID, SUM(TotalPrice) AS TotalSales
FROM Sales
GROUP BY MedicationID;
GO

--Total Quantity Sold for Each Medication
SELECT MedicationID, SUM(Quantity) AS TotalQuantitySold
FROM Sales
GROUP BY MedicationID;
GO

--Number of Prescriptions for Each Patient
SELECT PatientID, COUNT(PrescriptionID) AS NumberOfPrescriptions
FROM Prescriptions
GROUP BY PatientID;
GO

--Total Sales by Date
SELECT SaleDate, SUM(TotalPrice) AS DailyTotalSales
FROM Sales
GROUP BY SaleDate;
GO

--Medications Sold and Their Total Sales
SELECT M.Name, SUM(S.Quantity) AS TotalQuantitySold, SUM(S.TotalPrice) AS TotalSales
FROM Medications M
JOIN Sales S ON M.MedicationID = S.MedicationID
GROUP BY M.Name;
GO

-- Create PrescriptionsLog table to store logs
CREATE TABLE PrescriptionsLog (
    LogID INT PRIMARY KEY IDENTITY(1,1),
    PrescriptionID INT,
    LogMessage VARCHAR(255),
    LogDate DATETIME
);
GO

-- Create AFTER INSERT trigger for Prescriptions table
CREATE TRIGGER trg_AfterInsert_Prescriptions
ON Prescriptions
AFTER INSERT
AS
BEGIN
    INSERT INTO PrescriptionsLog (PrescriptionID, LogMessage, LogDate)
    SELECT PrescriptionID, 'New prescription added for PatientID: ' + CAST(PatientID AS VARCHAR), GETDATE()
    FROM inserted;
END;
GO

-- Create the merged table
CREATE TABLE PharmacyRecords (
    RecordID INT PRIMARY KEY IDENTITY(1,1),
    PatientID INT,
    PatientName VARCHAR(100),
    Age INT,
    Gender VARCHAR(10),
    PatientContact VARCHAR(15),
    PatientAddress VARCHAR(255),
    DoctorID INT,
    DoctorName VARCHAR(100),
    Specialty VARCHAR(50),
    DoctorContact VARCHAR(15),
    DoctorAddress VARCHAR(255),
    PrescriptionID INT,
    PrescriptionDate DATE,
    PrescriptionNotes TEXT,
    MedicationID INT,
    MedicationName VARCHAR(100),
    MedicationPrice DECIMAL(10, 2),
    SaleID INT,
    SaleDate DATE,
    SaleQuantity INT,
    TotalPrice DECIMAL(10, 2)
);
GO

-- Insert a new record into PharmacyRecords
INSERT INTO PharmacyRecords (PatientID, PatientName, Age, Gender, PatientContact, PatientAddress,
                             DoctorID, DoctorName, Specialty, DoctorContact, DoctorAddress,
                             PrescriptionID, PrescriptionDate, PrescriptionNotes, MedicationID,
                             MedicationName, MedicationPrice, SaleID, SaleDate, SaleQuantity, TotalPrice)
VALUES (1, 'Samiul', 30, 'Male', '123-456-7890', '123 Elm St',
        101, 'Dr. Arafat', 'Cardiology', '987-654-3210', '456 Oak St',
        1001, '2024-08-24', 'First prescription', 2001, 'Aspirin', 10.00,
        3001, '2024-08-24', 2, 20.00);
GO

-- Update a record in PharmacyRecords
UPDATE PharmacyRecords
SET PatientContact = '321-654-0987'
WHERE PatientID = 1;
GO

-- Delete a record from PharmacyRecords
DELETE FROM PharmacyRecords
WHERE RecordID = 1;
GO