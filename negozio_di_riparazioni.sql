-- Disabilitare temporaneamente le foreign key
SET FOREIGN_KEY_CHECKS = 0;

-- Eliminare le tabelle
DROP TABLE IF EXISTS Pagamento;
DROP TABLE IF EXISTS Ordine_Riparazione;
DROP TABLE IF EXISTS Fornisce;
DROP TABLE IF EXISTS OrdineComponenti;
DROP TABLE IF EXISTS Fornitore;
DROP TABLE IF EXISTS Componente;
DROP TABLE IF EXISTS Riparazione;
DROP TABLE IF EXISTS ListaDiAttesa;
DROP TABLE IF EXISTS Preventivo;
DROP TABLE IF EXISTS Difetto;
DROP TABLE IF EXISTS Apparecchio;
DROP TABLE IF EXISTS Cliente;


-- Riabilitare le foreign key
SET FOREIGN_KEY_CHECKS = 1;

-- Creazione tabelle

CREATE TABLE Cliente (
	CodiceFiscale CHAR(16) PRIMARY key,
    Nome VARCHAR(50) not null,
    Cognome VARCHAR(50) not null,
    TelefonoCellulare VARCHAR(15),
    Email VARCHAR(50),
    Città VARCHAR(50),
    Via VARCHAR(100),
    CAP CHAR(5)
);

CREATE TABLE Apparecchio (
	ID INT auto_increment PRIMARY key,
    Tipo VARCHAR(50) not null,
    Marca VARCHAR(50),
    Modello VARCHAR(50),
    CodiceFiscaleCliente CHAR(16),
    FOREIGN key (CodiceFiscaleCliente) references Cliente(CodiceFiscale) on delete cascade
);

CREATE TABLE Difetto (
	ID INT auto_increment Primary key,
    IDApparecchio INT,
    DescrizioneDifetto VARCHAR(255),
    FOREIGN key (IDApparecchio) references Apparecchio(ID) on delete cascade
);

CREATE TABLE Preventivo (
	ID INT auto_increment PRIMARY key,
    IDDifetto INT,
    IDApparecchio INT,
    DataCreazione DATE not null,
    Accettato BOOLEAN not null default FALSE,
    DescrizioneDifetto VARCHAR(255),
    FOREIGN key (IDDifetto) references Difetto(ID) on delete cascade,
    FOREIGN key (IDApparecchio) references Apparecchio(ID) on delete cascade
);

CREATE TABLE ListaDiAttesa (
	ID INT auto_increment PRIMARY key,
    IDPreventivo INT unique,
    DataInserimento DATE not null,
    FOREIGN key (IDPreventivo) references Preventivo(ID) on delete cascade
);

CREATE TABLE Riparazione (
	ID INT auto_increment PRIMARY key,
    IDLista INT unique,
    DataInizio DATE not null,
    DataFine DATE,
    FOREIGN key (IDLista) references ListaDiAttesa(ID) on delete cascade
);

CREATE TABLE Componente (
	ID INT auto_increment PRIMARY key,
    MarcaComponente VARCHAR(50),
    ModelloComponente VARCHAR(50),
    CostoAcquisto DECIMAL(10,2) not null,
    QtaDeposito INT default 0 check (QtaDeposito >= 0)
);

CREATE TABLE Fornitore (
	ID INT auto_increment PRIMARY key,
    Azienda VARCHAR(100) not null,
    Sede VARCHAR(100)
);

CREATE TABLE OrdineComponenti (
	ID INT auto_increment Primary key,
    DataOrdine DATE not null,
    DataRicezione DATE
);

CREATE TABLE Pagamento (
	ID INT auto_increment PRIMARY key,
    IDRiparazione INT unique,
    DataPagamento DATE not null,
    Importo DECIMAL(10,2) not null check (Importo >= 0),
    PagamentoElettronico BOOLEAN not null default FALSE,
    IncassoTotale DECIMAL(10,2),
    FOREIGN key (IDRiparazione) references Riparazione(ID) on delete cascade
);

-- Tabella relazione tra "Fornitore" e "OrdineComponenti" (N:N)
CREATE TABLE Fornisce (
	IDOrdine INT,
    IDFornitore INT,
    PRIMARY key (IDOrdine, IDFornitore),
    FOREIGN key (IDOrdine) references OrdineComponenti(ID) on delete cascade,
    FOREIGN key (IDFornitore) references Fornitore(ID) on delete cascade
);

-- Tabella relazione tra "OrdineComponenti" e "Riparazione" (N:N)
CREATE TABLE Ordine_Riparazione (
	IDOrdine INT,
    IDRiparazione INT,
    PRIMARY key (IDOrdine, IDRiparazione),
    FOREIGN key (IDOrdine) references OrdineComponenti(ID) on delete cascade,
    FOREIGN key (IDRiparazione) references Riparazione(ID) on delete cascade
);


-- Impedire che un "Apparecchio" venga consegnato più volte senza essere ritirato
DELIMITER //
CREATE TRIGGER Prima_Di_Inserire_Preventivo
Before insert on Preventivo
For each ROW
BEGIN
	DECLARE ApparecchioInRiparazione INT;
    
    Select COUNT(*) into ApparecchioInRiparazione
    From Riparazione R
    Join ListaDiAttesa L on R.IDLista = L.ID
    Join Preventivo P on L.IDPreventivo = P.ID
    Where P.IDApparecchio = NEW.IDApparecchio and R.DataFine is null;
    
    IF ApparecchioInRiparazione > 0 then
		Signal SQLSTATE '45000'
        Set Message_text = 'Impossibile accettare un nuovo preventivo: 1\' apparecchio è ancora in riparazione ';
	End If;
End;
//
DELIMITER ;

-- Impedire il pagamento di una riparazione non completata
DELIMITER //
CREATE TRIGGER Prima_Di_Inserire_Pagamento
Before insert on Pagamento
For each ROW
BEGIN
	DECLARE RiparazioneCompletata DATE;
    
    Select DataFine into RiparazioneCompletata
    From Riparazione
    Where ID = NEW.IDRiparazione;
    
    If RiparazioneCompletata is null then
		Signal SQLSTATE '45000'
        Set Message_Text = 'Impossibile registrare il pagamento: la riparazione non è ancora stata completata';
	End if;
End;
//
DELIMITER ;

-- Popolamento tabelle con 10 voci

-- Cliente
INSERT INTO Cliente (CodiceFiscale, Nome, Cognome, TelefonoCellulare, Email, Città, Via, CAP) VALUES
('RSSMRA85M01H501Z', 'Mario', 'Rossi', '3331112222', 'mario.rossi@example.com', 'Milano', 'Via Roma 1', '20100'),
('BNCLRD90D20F205X', 'Luca', 'Bianchi', '3332223333', 'luca.bianchi@example.com', 'Torino', 'Corso Italia 15', '10100'),
('VRDLGI85M01C351Z', 'Luigi', 'Verdi', '3333334444', 'luigi.verdi@example.com', 'Roma', 'Piazza Venezia 10', '00100'),
('BNTGRL92A01H501X', 'Giorgia', 'Bianchi', '3334445555', 'giorgia.bianchi@example.com', 'Napoli', 'Via Toledo 25', '80100'),
('BLUSRA98C01H621Z', 'Sara', 'Blu', '3335556666', 'sara.blu@example.com', 'Firenze', 'Via della Scala 5', '50100'),
('MLNLCU80D12H501Y', 'Luca', 'Milano', '3336667777', 'luca.milano@example.com', 'Genova', 'Via XX Settembre 12', '16100'),
('GNCRNC75F21A851Y', 'Francesco', 'Genchi', '3337778888', 'francesco.genchi@example.com', 'Bari', 'Via Sparano 8', '70100'),
('MRNGLA70L12C129Q', 'Giulia', 'Marino', '3338889999', 'giulia.marino@example.com', 'Palermo', 'Corso Vittorio Emanuele 7', '90100'),
('PLLMRC68E10A001B', 'Marco', 'Pallino', '3339990000', 'marco.pallino@example.com', 'Cagliari', 'Via Roma 30', '09100'),
('TRVRSA85H15C234P', 'Sara', 'Trevisan', '3330001111', 'sara.trevisan@example.com', 'Venezia', 'Piazza San Marco 2', '30100');

-- Apparecchio
INSERT INTO Apparecchio (Tipo, Marca, Modello, CodiceFiscaleCliente) VALUES
('Laptop', 'Dell', 'XPS 13', 'RSSMRA85M01H501Z'),
('Smartphone', 'Samsung', 'Galaxy S21', 'BNCLRD90D20F205X'),
('Tablet', 'Apple', 'iPad Pro', 'VRDLGI85M01C351Z'),
('PC', 'HP', 'EliteBook', 'BNTGRL92A01H501X'),
('Smartwatch', 'Garmin', 'Fenix 6', 'BLUSRA98C01H621Z'),
('Laptop', 'Asus', 'ZenBook 14', 'MLNLCU80D12H501Y'),
('Smartphone', 'Xiaomi', 'Redmi Note 10', 'GNCRNC75F21A851Y'),
('PC', 'Lenovo', 'ThinkPad T14', 'MRNGLA70L12C129Q'),
('Smartwatch', 'Apple', 'Watch Series 6', 'PLLMRC68E10A001B'),
('Tablet', 'Microsoft', 'Surface Pro', 'TRVRSA85H15C234P');

-- Difetto
INSERT INTO Difetto (IDApparecchio, DescrizioneDifetto) VALUES
(1, 'Batteria non si carica'),
(2, 'Schermo rotto'),
(3, 'Tasto home non funziona'),
(4, 'Problemi di surriscaldamento'),
(5, 'Sensore battito cardiaco non rileva dati'),
(6, 'WiFi instabile'),
(7, 'Microfono non funziona'),
(8, 'Problema con il touchpad'),
(9, 'Bluetooth non si connette'),
(10, 'Sistema operativo corrotto');

-- Preventivo
INSERT INTO Preventivo (IDDifetto, IDApparecchio, DataCreazione, Accettato, DescrizioneDifetto) VALUES
(1, 1, '2024-01-10', TRUE, 'Batteria non si carica'),
(2, 2, '2024-01-12', TRUE, 'Schermo rotto'),
(3, 3, '2024-01-15', FALSE, 'Tasto home non funziona'),
(4, 4, '2024-01-18', TRUE, 'Surriscaldamento'),
(5, 5, '2024-01-20', TRUE, 'Sensore non rileva dati'),
(6, 6, '2024-01-22', TRUE, 'WiFi instabile'),
(7, 7, '2024-01-25', FALSE, 'Microfono non funziona'),
(8, 8, '2024-01-28', TRUE, 'Touchpad non risponde'),
(9, 9, '2024-02-01', TRUE, 'Bluetooth non si connette'),
(10, 10, '2024-02-03', TRUE, 'Sistema operativo corrotto');

-- Lista di attesa
INSERT INTO ListaDiAttesa (IDPreventivo, DataInserimento) VALUES
(1, '2024-01-11'),
(2, '2024-01-13'),
(4, '2024-01-19'),
(5, '2024-01-21'),
(6, '2024-01-23'),
(8, '2024-01-29'),
(9, '2024-02-02'),
(10, '2024-02-04');

-- Riparazione
INSERT INTO Riparazione (IDLista, DataInizio, DataFine) VALUES
(1, '2024-01-12', '2024-01-14'),
(2, '2024-01-14', '2024-01-16'),
(3, '2024-01-20', '2024-01-22'),
(4, '2024-01-22', '2024-01-25'),
(5, '2024-01-24', NULL),
(6, '2024-01-30', NULL),
(7, '2024-02-03', NULL),
(8, '2024-02-05', NULL);

-- Componente
INSERT INTO Componente (MarcaComponente, ModelloComponente, CostoAcquisto, QtaDeposito) VALUES
('Samsung', 'Batteria Li-ion', 30.00, 5),
('Apple', 'Schermo OLED', 150.00, 2),
('HP', 'Touchpad Precision', 40.00, 3),
('Xiaomi', 'Microfono', 20.00, 6),
('Garmin', 'Sensore Cardiaco', 50.00, 4),
('Lenovo', 'WiFi Adapter', 35.00, 8),
('Dell', 'Altoparlante', 25.00, 5),
('Microsoft', 'Modulo Bluetooth', 45.00, 7),
('Asus', 'Scheda Madre', 120.00, 1),
('Acer', 'Batteria 4000mAh', 60.00, 9);

-- Fornitore
INSERT INTO Fornitore (ID, Azienda, Sede) VALUES
(1, 'TechParts', 'Milano'),
(2, 'PowerUp', 'Torino'),
(3, 'SoundFix', 'Roma'),
(4, 'NavParts', 'Napoli'),
(5, 'MemStore', 'Firenze'),
(6, 'CoolTech', 'Genova'),
(7, 'AudioPlus', 'Bari'),
(8, 'ImagePro', 'Palermo'),
(9, 'ConnectX', 'Cagliari'),
(10, 'BlueWave', 'Venezia');

-- OrdineComponenti
INSERT INTO OrdineComponenti (ID, DataOrdine, DataRicezione) VALUES
(1, '2024-01-05', '2024-01-10'),
(2, '2024-01-06', '2024-01-11'),
(3, '2024-01-07', '2024-01-12'),
(4, '2024-01-08', '2024-01-13'),
(5, '2024-01-09', '2024-01-14'),
(6, '2024-01-10', '2024-01-15'),
(7, '2024-01-11', '2024-01-16'),
(8, '2024-01-12', '2024-01-17'),
(9, '2024-01-13', '2024-01-18'),
(10, '2024-01-14', '2024-01-19');

-- Pagamento
INSERT INTO Pagamento (IDRiparazione, DataPagamento, Importo, PagamentoElettronico, IncassoTotale) VALUES
(1, '2024-01-14', 120.00, TRUE, 120.00),
(2, '2024-01-16', 250.00, FALSE, 250.00),
(3, '2024-01-22', 80.00, TRUE, 80.00),
(4, '2024-01-25', 180.00, FALSE, 180.00);

-- Fornisce (Relazione N:N fra Fornitore e OrdineComponenti)
INSERT INTO Fornisce (IDOrdine, IDFornitore) VALUES
(1, 1),
(1, 2),
(2, 3),
(3, 1),
(3, 4),
(4, 2),
(5, 3),
(6, 4),
(7, 5),
(8, 1);

-- Ordine_Riparazione (Relazione N:N tra OrdineComponenti e Riparazione)
INSERT INTO Ordine_Riparazione (IDOrdine, IDRiparazione) VALUES
(1, 1),
(2, 2),
(3, 3),
(3, 4),
(4, 5),
(5, 6),
(6, 7),
(7, 8),
(8, 2),
(9, 4);


-- Query per interrogare il DataBase

-- Inserimento di un nuovo cliente
INSERT INTO Cliente (CodiceFiscale, Nome, Cognome, TelefonoCellulare, Email, Città, Via, CAP) 
VALUES ('4GNEWCUST75L12X1', 'Andrea', 'Ferrari', '3338889999', 'andrea.ferrari@example.com', 'Torino', 'Via Garibaldi 88', '10100');

-- Inserimento di un nuovo apparecchio
INSERT INTO Apparecchio (Tipo, Marca, Modello, CodiceFiscaleCliente) 
VALUES ('Laptop', 'HP', 'Pavilion x360', '4GNEWCUST75L12X1');

-- Inserimento di un nuovo preventivo
INSERT INTO Preventivo (IDDifetto, IDApparecchio, DataCreazione, Accettato, DescrizioneDifetto) 
VALUES (11, LAST_INSERT_ID(), '2024-02-20', TRUE, 'Problema alla scheda madre');

-- Inserimento di una nuova riparazione passando prima per la lista di attesa
INSERT INTO ListaDiAttesa (IDPreventivo, DataInserimento) 
VALUES (LAST_INSERT_ID(), '2024-02-21');

INSERT INTO Riparazione (IDLista, DataInizio, DataFine) 
VALUES (LAST_INSERT_ID(), '2024-02-22', NULL);

-- Inserimento di un nuovo componente
INSERT INTO Componente (MarcaComponente, ModelloComponente, CostoAcquisto, QtaDeposito) 
VALUES ('Intel', 'Processore i7 11th Gen', 320.00, 5);

-- Effettuare un nuovo OrdineComponenti poi aggiungo il collegamento al fornitore
INSERT INTO OrdineComponenti (DataOrdine, DataRicezione) 
VALUES ('2024-02-22', NULL);
INSERT INTO Fornisce (IDOrdine, IDFornitore) 
VALUES (LAST_INSERT_ID(), 3);

-- Inserire un nuovo pagamento
INSERT INTO Pagamento (IDRiparazione, DataPagamento, Importo, PagamentoElettronico, IncassoTotale) 
VALUES (LAST_INSERT_ID(), '2024-02-25', 400.00, TRUE, 400.00);

-- Calcolo incassi annuali
SELECT DATE_FORMAT(DataPagamento, '%Y-%m') AS Mese, SUM(Importo) AS TotaleIncassato
FROM Pagamento
GROUP BY Mese
ORDER BY Mese DESC;

-- Elencare tutti i clienti con i loro apparecchi registrati
Select C.CodiceFiscale, C.Nome, C.Cognome, A.Tipo, A.Marca, A.Modello
From Cliente C
Join Apparecchio A on C.CodiceFiscale = A.CodiceFiscaleCliente;

-- Trovare il numero di apparecchi registrati per cliente
Select C.Nome, C.Cognome, COUNT(A.ID) as NumeroApparecchi
From Cliente C
Left Join Apparecchio A on C.CodiceFiscale = A.CodiceFiscaleCliente
Group by C.CodiceFiscale;

-- Mostrare i preventivi accettati con i dettagli degli apparecchi e dei clienti
Select P.ID, C.Nome, C.Cognome, A.Tipo, A.Marca, A.Modello, P.DataCreazione, P.Accettato
From Preventivo P
Join Apparecchio A on P.IDApparecchio = A.ID
Join Cliente C on A.CodiceFiscaleCliente = C.CodiceFiscale
Where P.Accettato = TRUE;

-- Trovare gli apparecchi attualmente in riparazione
Select A.Tipo, A.Marca, A.Modello, C.Nome, C.Cognome, R.DataInizio
From Riparazione R
Join ListaDiAttesa L on R.IDLista = L.ID
Join Preventivo P on L.IDPreventivo = P.ID
Join Apparecchio A on P.IDApparecchio = A.ID
Join Cliente C on A.CodiceFiscaleCliente = C.CodiceFiscale
Where R.DataFine is not null;

-- Mostrare le riparazioni completate in un determinato intervallo di tempo
SELECT A.Tipo, A.Marca, A.Modello, C.Nome, C.Cognome, R.DataInizio, R.DataFine
FROM Riparazione R
JOIN ListaDiAttesa L ON R.IDLista = L.ID
JOIN Preventivo P ON L.IDPreventivo = P.ID
JOIN Apparecchio A ON P.IDApparecchio = A.ID
JOIN Cliente C ON A.CodiceFiscaleCliente = C.CodiceFiscale
WHERE R.DataFine BETWEEN '2024-01-01' AND '2024-01-31'
ORDER BY R.DataFine ASC;

-- Mostrare gli ordini di componenti non ancora ricevuti
Select OC.ID, C.MarcaComponente, C.ModelloComponente, OC.DataOrdine
From  OrdineComponenti OC
Join Fornisce F on OC.ID = F.IDOrdine
Join Componente C on F.IDOrdine = C.ID
Where OC.DataRicezione is not null;

-- Elenco dei componenti disponibili in magazzino con quantità inferiore a 5
Select ID, MarcaComponente, ModelloComponente, QtaDeposito
From Componente
Where QtaDeposito < 5;

-- Calcolo incasso totale mensile
Select DATE_FORMAT(DataPagamento, '%Y-%m') as Mese, SUM(Importo) as TotaleIncassato
From Pagamento
Group by Mese
Order by Mese Desc;

-- Mostrare i pagamenti effettuati in un determinato intervallo di tempo
Select P.ID, R.ID as IDRiparazione, C.Nome, C.Cognome, P.Importo, P.DataPagamento
From Pagamento P
Join Riparazione R on P.IDRiparazione = R.ID
Join ListaDiAttesa L on R.IDLista = L.ID
Join Preventivo PR on L.IDPreventivo = PR.ID
Join Apparecchio A on PR.IDApparecchio = A.ID
Join Cliente C on A.CodiceFiscaleCliente = C.CodiceFiscale
Where P.DataPagamento between '2024-01-01' and '2024-12-31';

-- Visualizzare la lista di attesa in ordine di arrivo
Select L.ID, P.ID as IDPreventivo, C.Nome, C.Cognome, A.Tipo, A.Marca, A.Modello, L.DataInserimento
From ListaDiAttesa L
Join Preventivo P on L.IDPreventivo = P.ID
Join Apparecchio A on P.IDApparecchio = A.ID
Join Cliente C on A.CodiceFiscaleCliente = C.CodiceFiscale
Order by L.DataInserimento ASC;

-- Mostrare gli apparecchi che hanno avuto più di una riparazione
Select A.Tipo, A.Marca, A.Modello, C.Nome, C.Cognome, COUNT(R.ID) as NumeroRiparazioni
From Riparazione R
Join ListaDiAttesa L on R.IDLista = L.ID
Join Preventivo P on L.IDPreventivo = P.ID
Join Apparecchio A on P.IDApparecchio = A.ID
Join Cliente C on A.CodiceFiscaleCliente = C.CodiceFiscale
Group by A.ID
Having COUNT(R.ID) > 1;

-- Test per "Prima_Di_Inserire_Preventivo"
INSERT INTO Preventivo (IDDifetto, IDApparecchio, DataCreazione, Accettato, DescrizioneDifetto) 
VALUES (6, 6, '2024-01-22', TRUE, 'WiFi instabile di nuovo');

-- Test per "Prima_Di_Inserire_Pagamento"
INSERT INTO Pagamento (IDRiparazione, DataPagamento, Importo, PagamentoElettronico, IncassoTotale) 
VALUES (5, '2024-02-12', 150.00, TRUE, 150.00);
