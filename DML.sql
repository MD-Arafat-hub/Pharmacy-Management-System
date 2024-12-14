--Md.Arafat (1284966)

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

-- Execute AddNewPrescription stored procedure
EXEC AddNewPrescription
    @PatientID = 1, 
    @DoctorID = 2, 
    @Date = '2024-08-18',
    @Notes = 'Take as prescribed.',
    @MedicationID = 1,
    @Quantity = 30,
    @Dosage = '500mg';
GO

-- Query to get all records from MedicationChangesLog
SELECT * FROM MedicationChangesLog;
GO

-- Query using the scalar function
SELECT dbo.CalculateTotalPrice(15.75, 10) AS TotalPrice;
GO

-- Query using the table function
SELECT * FROM dbo.GetLowStockMedications(50);
GO

-- Query using the multi-statement table function
SELECT * FROM dbo.GetPatientPrescriptions(1);
GO

-- Query to get data from views
SELECT * FROM EncryptedPatientView;
SELECT * FROM MedicationView;
SELECT * FROM EncryptedBoundPrescriptionView;
GO

-- Query using subquery
SELECT Name
FROM Patients
WHERE PatientID IN (
    SELECT DISTINCT PatientID
    FROM Prescriptions
);
GO

-- Query using CTE to get patients with their prescriptions
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

-- Query to get total stock quantity of medications
SELECT SUM(StockQuantity) AS TotalStock
FROM Medications;
GO

-- Query to get average price of medications
SELECT AVG(Price) AS AveragePrice
FROM Medications;
GO

-- Query to get total sales amount for each medication
SELECT MedicationID, SUM(TotalPrice) AS TotalSales
FROM Sales
GROUP BY MedicationID;
GO

-- Query to get total quantity sold for each medication
SELECT MedicationID, SUM(Quantity) AS TotalQuantitySold
FROM Sales
GROUP BY MedicationID;
GO

-- Query to get the number of prescriptions for each patient
SELECT PatientID, COUNT(PrescriptionID) AS NumberOfPrescriptions
FROM Prescriptions
GROUP BY PatientID;
GO

-- Query to get total sales by date
SELECT SaleDate, SUM(TotalPrice) AS DailyTotalSales
FROM Sales
GROUP BY SaleDate;
GO

-- Query to get medications sold and their total sales
SELECT M.Name, SUM(S.Quantity) AS TotalQuantitySold, SUM(S.TotalPrice) AS TotalSales
FROM Medications M
JOIN Sales S ON M.MedicationID = S.MedicationID
GROUP BY M.Name;
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


