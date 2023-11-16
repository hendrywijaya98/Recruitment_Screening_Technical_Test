USE JBIA_Indodana;

-- CREATE TABLE PEOPLE( FirstName VARCHAR(30), LastName VARCHAR(30), 
-- City VARCHAR(30), Weight INT, Gender VARCHAR(10), Province VARCHAR(30));
-- ALTER TABLE LOAN_CONTRACT_LEDGERS
-- ADD FOREIGN KEY (contract_id) REFERENCES LOAN_CONTRACTS(contract_id);

/*LOAN_CONTRACTS -> Loan Account
created_at : Timestamp of contact created
contract_status	: active, finished , cancelled
tenure : Duration of loan in months 
provision : biaya pengajuan pinjaman yang disetujui
principal :  jumlah pokok dari pinjaman sesuai jumlah loan_amount + interest (bunga)
*/

SELECT * FROM LOAN_CONTRACTS;

-- CONTRACTS SUMMARY OVERVIEW
SELECT contract_status, tenure, COUNT(contract_id) as num_contracts, SUM(loan_amount) total_amount, 
		SUM(provision) total_provision, SUM(interest) total_interest, SUM(principal) total_principal
FROM LOAN_CONTRACTS GROUP BY contract_status, tenure;

-- total loan, provision, interest and principal by contract status
SELECT contract_status, SUM(loan_amount) total_amount, SUM(provision) total_provision, 
		SUM(interest) total_interest, SUM(principal) total_principal
FROM LOAN_CONTRACTS GROUP BY contract_status;

-- total loan, provision, interest and principal by tenure
SELECT tenure, SUM(loan_amount) total_amount, SUM(provision) total_provision, 
		SUM(interest) total_interest, SUM(principal) total_principal
FROM LOAN_CONTRACTS GROUP BY tenure;

-- num of contracts by status
SELECT contract_status, COUNT(DISTINCT contract_id) as num_contracts
FROM LOAN_CONTRACTS GROUP BY contract_status

-- number of contracts by tenure
SELECT tenure, COUNT(DISTINCT contract_id) as num_contracts
FROM LOAN_CONTRACTS GROUP BY tenure

-- num of contract by status and tenure
SELECT contract_status, tenure, COUNT(DISTINCT contract_id) as num_contracts
FROM LOAN_CONTRACTS GROUP BY contract_status, tenure


-- INTERPROV_SUSPECT_DETECTION
WITH suspicious_interest_provision AS
(SELECT loan_amount, interest, (loan_amount*0.40) as loan_inter, provision, 
(loan_amount*0.40) as loan_prov, AVG(interest) OVER() AS avg_interest, 
AVG(provision) over() as avg_provision FROM LOAN_CONTRACTS)
SELECT loan_amount, interest, loan_inter, avg_interest,
	CASE WHEN loan_inter < interest THEN 'SUSPECTED' ELSE 'Save' END as interest_suspect, 
	provision, loan_prov, avg_provision,
	CASE WHEN loan_prov < provision THEN 'SUSPECTED' ELSE 'Save' END as provision_suspect,
	CASE WHEN provision < interest then 'SUSPECTED' ELSE 'Save' END as interprov_suspect
FROM suspicious_interest_provision

-- LOAN_ANOMALY_DETECTION
WITH contract_stats AS
(SELECT contract_status, AVG(loan_amount) as avg_loan, AVG(provision) as avg_provision, AVG(interest) as avg_interest, 
		AVG(principal) as avg_principal, STDEV(loan_amount) - AVG(loan_amount) as rsd_loan, 
		STDEV(provision) - AVG(provision) as rsd_prov, STDEV(interest) - AVG(interest) as rsd_inter, 
		STDEV(principal) - AVG(principal) as rsd_prin
FROM LOAN_CONTRACTS GROUP BY contract_status) 
SELECT CONVERT(CHAR(5), lc.created_at, 108) as created_time, cs.contract_status, lc.loan_amount, lc.provision, 
		lc.interest, lc.principal, cs.avg_loan, cs.rsd_loan, cs.avg_provision, cs.rsd_prov, cs.avg_interest, 
		cs.rsd_inter, cs.avg_principal, cs.rsd_prin, ABS(1 - lc.loan_amount/ cs.avg_loan) as loan_avg_dis, 
		ABS(1 - lc.provision/ cs.avg_provision)  as prov_avg_dis, ABS(1 - lc.interest/ cs.avg_interest) as int_avg_dis, 
		ABS(1 - lc.principal/ cs.avg_principal) as prin_avg_dis,
		CASE WHEN cs.rsd_loan <= 0.2 AND ABS(1 - lc.loan_amount/ cs.avg_loan) >= 0.4 
			THEN 'anomaly' ELSE 'normal' END AS loan_flag, 
		CASE WHEN cs.rsd_inter <= 0.2 AND ABS(1 - lc.provision/ cs.avg_provision) >= 0.4 
			THEN 'anomaly' ELSE 'normal' END AS provision_lag, 
		CASE WHEN cs.rsd_prov <= 0.2 AND ABS(1 - lc.interest/ cs.avg_interest) >= 0.4 
			THEN 'anomaly' ELSE 'normal' END AS interest_flag, 
		CASE WHEN cs.rsd_prin <= 0.2 AND ABS(1 - lc.principal/ cs.avg_principal) >= 0.4 
				THEN 'anomaly' ELSE 'normal' END AS principal_flag
FROM LOAN_CONTRACTS as lc JOIN contract_stats cs ON lc.contract_status = cs.contract_status;



/*LOAN_CONTRACT_LEDGERS -> list of installment per loan account
created_at : Timestamp of contact created
ledger_type : principal, interest, late_fee , restructure_down_payment
ledger_status : paid, unpaid, partially_paid, cancelled, waived (hutang dibebaskan)
period : waktu yang diperlukan untuk melunasi pinjaman oleh borrower
due_date : timestamp when the installment due
paid_off_date : timestamp when the installment is paid
*/

SELECT * FROM LOAN_CONTRACT_LEDGERS;

-- LEDGER ANOMALY DETECTION
WITH ledger_anomaly AS (
SELECT ledger_status, ledger_type, CAST(due_date as DATE) as due_date, 
	   CAST(paid_off_date as DATE) as paid_off_date, 
	   AVG(initial_balance) as avg_init_bal, AVG(balance) as avg_balance, 
	   ISNULL(NULLIF(STDEV(initial_balance),0) / AVG(initial_balance),0) as rsd_inibal, 
	   ISNULL(NULLIF(STDEV(balance),0) / AVG(balance),0) as rsd_balance
FROM LOAN_CONTRACT_LEDGERS GROUP BY ledger_status, ledger_type, 
	CAST(due_date as DATE), CAST(paid_off_date as DATE))
SELECT la.ledger_status, la.ledger_type, la.due_date, la.paid_off_date, lcl.initial_balance, lcl.balance,
		CASE WHEN lcl.initial_balance = 0 or la.avg_init_bal = 0 
				THEN 0 ELSE ABS(1 - lcl.initial_balance / la.avg_init_bal) END as inibal_avg_dis,
		CASE WHEN lcl.balance = 0  or la.avg_balance = 0 
				THEN 0 ELSE ABS(1 - lcl.balance / la.avg_balance) END as bal_avg_dis,
		CASE WHEN la.rsd_inibal <= 0.2 AND (CASE WHEN lcl.initial_balance = 0 or la.avg_init_bal = 0 
				THEN 0 ELSE ABS(1 - lcl.initial_balance / la.avg_init_bal) END) >= 0.4 
					THEN 'anomaly' ELSE 'normal' END AS inibal_flag,
		CASE WHEN la.rsd_balance <= 0.2 AND (CASE WHEN lcl.balance = 0 or la.avg_balance = 0 
				THEN 0 ELSE ABS(1 - lcl.balance / la.avg_balance) END) >= 0.4 
					THEN 'anomaly' ELSE 'normal' END AS balance_flag
FROM LOAN_CONTRACT_LEDGERS lcl JOIN ledger_anomaly la ON lcl.ledger_status = la.ledger_status
 

-- LEDGERS SUMMARY OVERVIEW
SELECT ledger_type, ledger_status, period, COUNT(contract_id) as total_contracts, 
		SUM(initial_balance) as total_init_balance, SUM(balance) total_balance 
FROM LOAN_CONTRACT_LEDGERS GROUP BY ledger_type, ledger_status, period;

-- jumlah saldo pinjaman per periode pelunasan
SELECT period, SUM(initial_balance) as total_init_balance, SUM(balance) total_balance 
FROM LOAN_CONTRACT_LEDGERS GROUP BY period;

-- jumlah saldo pinjaman per jenis pembukuan / ledger
SELECT ledger_type, SUM(initial_balance) as total_init_balance, SUM(balance) total_balance 
FROM LOAN_CONTRACT_LEDGERS GROUP BY ledger_type;

-- jumlah saldo pinjaman per status pembukuan / ledger
SELECT ledger_status, SUM(initial_balance) as total_init_balance, SUM(balance) total_balance 
FROM LOAN_CONTRACT_LEDGERS GROUP BY ledger_status;

-- jumlah saldo pinjaman sesuai pembukuan 
SELECT ledger_type, ledger_status, SUM(initial_balance) as total_init_balance, SUM(balance) total_balance 
FROM LOAN_CONTRACT_LEDGERS GROUP BY ledger_type, ledger_status;

-- jumlah kontrak pinjaman per status ledger
SELECT ledger_status, COUNT(contract_id) as total_contracts 
FROM LOAN_CONTRACT_LEDGERS GROUP BY ledger_status;



-- jumlah pembukuan per jenis ledger
SELECT ledger_type, COUNT(ledger_id) as num_ledger 
FROM LOAN_CONTRACT_LEDGERS GROUP BY ledger_type;

-- jumlah pembukuan per status ledger
SELECT ledger_status, COUNT(ledger_id) as num_ledger 
FROM LOAN_CONTRACT_LEDGERS GROUP BY ledger_status;

SELECT ledger_type, ledger_status, COUNT(ledger_id) as num_ledger 
FROM LOAN_CONTRACT_LEDGERS GROUP BY ledger_type, ledger_status;


SELECT lc.contract_status, lcl.ledger_status, lcl.ledger_type, lc.tenure, lcl.period, lc.contract_id, 
		lc.loan_amount, lcl.ledger_id, lc.provision, lc.interest, lc.principal, lcl.initial_balance, lcl.balance
FROM LOAN_CONTRACTS as lc JOIN LOAN_CONTRACT_LEDGERS as lcl ON lc.contract_id = lcl.contract_id

SELECT lc.contract_status, lcl.ledger_status, lcl.ledger_type, COUNT(lc.contract_id) as num_contracts, 
		ROUND(SUM(lcl.initial_balance),2) as total_init_bal, ROUND(SUM(lcl.balance),2) as total_balance
FROM LOAN_CONTRACTS as lc JOIN LOAN_CONTRACT_LEDGERS as lcl ON lc.contract_id = lcl.contract_id
GROUP BY lc.contract_status, lcl.ledger_status, lcl.ledger_type

SELECT MONTH(lcl.due_date) as due_month, YEAR(lcl.due_date) as due_year, lc.loan_amount, 
	  lc.provision, lc.interest, lc.principal, lcl.initial_balance, lcl.balance
FROM LOAN_CONTRACTS as lc JOIN LOAN_CONTRACT_LEDGERS as lcl ON lc.contract_id = lcl.contract_id

SELECT MONTH(lcl.due_date) as due_month, YEAR(lcl.due_date) as due_year, SUM(lc.loan_amount), 
	 SUM(lc.interest), SUM(lc.principal), SUM(lcl.initial_balance), SUM(lcl.balance)
FROM LOAN_CONTRACTS as lc JOIN LOAN_CONTRACT_LEDGERS as lcl ON lc.contract_id = lcl.contract_id
GROUP BY  MONTH(lcl.due_date), YEAR(lcl.due_date)

-- CONTRACT LEDGER SUMMARY 
SELECT lc.contract_status, lcl.ledger_status, lcl.ledger_type, lc.tenure, lcl.period, 
	   COUNT(lc.contract_id) as total_contracts, SUM(lc.loan_amount) as total_loan, COUNT(lcl.ledger_id) as total_ledger, 
	   SUM(lc.provision) as total_provision, SUM(lc.interest) as total_interest, SUM(lc.principal) as total_principal, 
		SUM(lcl.initial_balance) as total_initbal, SUM(lcl.balance) as total_balance
FROM LOAN_CONTRACTS as lc JOIN LOAN_CONTRACT_LEDGERS as lcl ON lc.contract_id = lcl.contract_id
GROUP BY lc.contract_status, lcl.ledger_status, lcl.ledger_type, lc.tenure, lcl.period

-- the expected repayment amount without late payment or loan restructure in assumption 
-- from each principal & interest in the month of Aug, Sept & Oct
SELECT 	exp_amt.due_month, exp_amt.due_year, ROUND(SUM(exp_amt.initial_balance),2) as total_initial_balance, 
		ROUND(SUM(exp_amt.balance),2) as total_balance FROM 
(SELECT lc.contract_id, lc.created_at, lc.contract_status, lc.tenure, lc.loan_amount, lc.provision, 
	lc.interest, lc.principal, lcl.period, lcl.ledger_type, lcl.ledger_status, lcl.initial_balance, lcl.balance,
	MONTH(lcl.due_date) as due_month, YEAR(lcl.due_date) as due_year, 
	MONTH(lcl.paid_off_date) as paidoff_month, YEAR(lcl.paid_off_date) as paidoff_year
FROM LOAN_CONTRACTS lc JOIN LOAN_CONTRACT_LEDGERS lcl ON lc.contract_id = lcl.contract_id
WHERE NOT lcl.ledger_type IN ('RESTRUCTURE_DOWN_PAYMENT','LATE_FEE') AND MONTH(lcl.due_date) IN (8,9,10)) as exp_amt 
GROUP BY exp_amt.due_month, exp_amt.due_year ORDER BY exp_amt.due_month, exp_amt.due_year DESC;

-- LateFee amount which has been waived for each contract status
SELECT contract_status, ledger_type, ledger_status, SUM(loan_amount) as lfw_loan_amount, 
	   SUM(principal) as lfw_principal, SUM(initial_balance) as lfw_initbalance, SUM(balance) as lfw_balance 
FROM (SELECT lc.contract_status, lcl.ledger_status, lcl.ledger_type, lc.tenure, lc.loan_amount, 
	   lc.provision, lc.interest, lc.principal, lcl.initial_balance, lcl.balance 
FROM LOAN_CONTRACTS lc JOIN LOAN_CONTRACT_LEDGERS lcl ON lc.contract_id = lcl.contract_id
WHERE lcl.ledger_type = 'LATE_FEE' AND lcl.ledger_status='WAIVED') as latefee_waived
GROUP BY contract_status, ledger_type, ledger_status