--Md.Arafat(1284966)
USE master;
GO

-- Drop existing database if it exists
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Pharmacy_Management')
BEGIN
    DROP DATABASE Pharmacy_Management;
END
GO

-- Create new database
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
--use database
USE Pharmacy_Management;
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

-- Create MedicationChangesLog table
CREATE TABLE MedicationChangesLog (
    LogID INT PRIMARY KEY IDENTITY(1,1),
    MedicationID INT,
    ChangeType NVARCHAR(10),
    ChangeDate DATETIME DEFAULT GETDATE(),
    OldQuantity INT,
    NewQuantity INT
);
GO

-- Create AddNewPrescription stored procedure
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

-- Create trigger for MedicationChangesLog
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

-- Scalar Function with CalculateTotalPrice
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

-- Table Function with GetLowStockMedications
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

-- Multi-statement Table Function GetPatientPrescriptions
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

-- View with Encryption EncryptedPatientView
CREATE VIEW EncryptedPatientView
WITH ENCRYPTION
AS
SELECT PatientID, Name, Age, Gender, Contact
FROM Patients;
GO

-- View with Schema Binding MedicationView
CREATE VIEW MedicationView
WITH SCHEMABINDING
AS
SELECT MedicationID, Name, Price, StockQuantity
FROM dbo.Medications;
GO

-- View with Both Encryption and SCHEMABINDING 
CREATE VIEW EncryptedBoundPrescriptionView
WITH ENCRYPTION, SCHEMABINDING
AS
SELECT p.PrescriptionID, p.Date, d.Name AS DoctorName, pt.Name AS PatientName
FROM dbo.Prescriptions p
INNER JOIN dbo.Doctors d ON p.DoctorID = d.DoctorID
INNER JOIN dbo.Patients pt ON p.PatientID = pt.PatientID;
GO

-- Create a non-clustered index on the Name column
CREATE NONCLUSTERED INDEX IX_PatientName
ON Patients (Name);
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
