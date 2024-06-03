
--1a
SELECT DISTINCT (npi), SUM(total_claim_count) AS total_count_claims
FROM prescriber INNER JOIN prescription USING (npi)
GROUP BY npi
ORDER BY total_count_claims DESC ;
--Answer: npi: 1881634483 / total claims:	99707

--1b
SELECT prescriber.nppes_provider_last_org_name AS prescriber_last_name, nppes_provider_first_name AS prescriber_first_name, specialty_description, SUM(total_claim_count) AS total_count_claims
FROM prescriber INNER JOIN prescription USING (npi)
GROUP BY prescriber_last_name, prescriber_first_name, specialty_description
ORDER BY total_count_claims DESC ;
--Answer: table of the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims

--2a
SELECT DISTINCT (specialty_description), SUM (total_claim_count) AS total_count_claims
FROM prescriber INNER JOIN prescription USING (npi)
GROUP BY specialty_description
ORDER BY total_count_claims DESC ;
--Answer: "Family Practice" & total count of claims: 9752347

--2b
SELECT DISTINCT (prescriber.specialty_description), SUM (total_claim_count) AS total_count_claims
FROM prescriber INNER JOIN prescription USING (npi)
				INNER JOIN drug USING (drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY prescriber.specialty_description
ORDER BY total_count_claims DESC ;
--Answer: "Nurse Practitioner" & total count of claims:	900845

--2c
SELECT specialty_description, SUM(total_30_day_fill_count) AS total_count_prescriptions
FROM prescriber LEFT JOIN prescription USING (npi)
GROUP BY specialty_description
ORDER BY total_count_prescriptions DESC ;
--Answer: table of specialties that appear in the prescriber table that have no associated prescriptions in the prescription table

--2d *** WORK ON THIS***
WITH all_drugs AS (SELECT DISTINCT (prescriber.specialty_description), total_claim_count
FROM prescriber INNER JOIN prescription USING (npi)
				INNER JOIN drug USING (drug_name)
				WHERE opioid_drug_flag = 'Y'
				GROUP BY prescriber.specialty_description, total_claim_count)	
SELECT specialty_description, total_claim_count
FROM all_drugs
FROM percentage
--if ran w/o WHERE and 'Y' there are results for total but you need to tie up to calculate opiod claims devided by total claims

--3a
SELECT DISTINCT(drug.generic_name), SUM(total_drug_cost) AS total_cost
FROM drug INNER JOIN prescription USING (drug_name)
GROUP BY drug.generic_name
ORDER BY total_cost DESC ;
--Answer: "INSULIN GLARGINE,HUM.REC.ANLOG" & total cost:	104264066.35

--3b
SELECT DISTINCT(drug.generic_name), ROUND (SUM(total_drug_cost) / SUM(total_day_supply), 2) AS cost_per_diem
FROM drug INNER JOIN prescription USING (drug_name) 
GROUP BY drug.generic_name
ORDER BY cost_per_diem DESC ;
--Answer: "C1 ESTERASE INHIBITOR" & cost per diem:	3495.22

--4a
WITH drug_type AS (SELECT *,
	   CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			ELSE 'neither' END AS drug_type
			FROM drug)
			
SELECT drug_name, drug_type 
FROM drug_type ;
--Answer: table of 'drug_types'		

--4b
WITH drug_type AS (SELECT *,
	   CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			ELSE 'neither' END AS drug_type
			FROM drug)
			
SELECT drug_type.drug_type, SUM(prescription.total_drug_cost)::money AS total_cost_by_type
FROM drug_type LEFT JOIN prescription USING (drug_name)	
GROUP BY drug_type.drug_type ;
--Answer: table of drugtype & total cost	

--5a
SELECT COUNT (DISTINCT cbsa) AS tn_cbsa
FROM cbsa
WHERE cbsaname LIKE '%TN%' ;
--Answer: 10

--option#2
SELECT COUNT (DISTINCT cbsa) AS tn_cbsa
FROM cbsa INNER JOIN fips_county USING (fipscounty)
WHERE state = 'TN' ;
--Answer: 10

--5b
SELECT DISTINCT (cbsaname), SUM (population) AS total_pop
FROM population INNER JOIN cbsa USING (fipscounty)
				INNER JOIN fips_county USING (fipscounty)
GROUP BY cbsaname
ORDER BY total_pop DESC ;
--Answer: table of cbsa with total pop with descending order (max & min respectively)
--"Nashville-Davidson--Murfreesboro--Franklin, TN" & 1830410
--"Morristown, TN" & 116352

--5c
SELECT county, state, population
FROM fips_county LEFT JOIN cbsa USING (fipscounty)
				 LEFT JOIN population USING (fipscounty)
WHERE cbsa IS NULL
ORDER BY population DESC NULLS LAST ;
--Answer: "SEVIER"	"TN" &	95523 as population

--6a
SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count > 3000
ORDER BY total_claim_count DESC ;
--Answer: table with 9 drugs

--6b
SELECT drug_name, opioid_drug_flag, prescription.total_claim_count
FROM prescription LEFT JOIN drug USING (drug_name)
WHERE total_claim_count > 3000 AND opioid_drug_flag = 'Y'
GROUP BY drug_name, opioid_drug_flag, prescription.total_claim_count
ORDER BY total_claim_count DESC
--Answer: 2 out of 9 drugs are opioids

--6c
SELECT drug_name, opioid_drug_flag, prescription.total_claim_count, prescriber.nppes_provider_last_org_name, prescriber.nppes_provider_first_name
FROM prescription LEFT JOIN drug USING (drug_name)
				  LEFT JOIN prescriber USING (npi)
WHERE total_claim_count > 3000 AND opioid_drug_flag = 'Y'
--Answer: David Coffey and same 2 opioids with 3000+ claims

--7a
SELECT prescriber.npi, prescriber.nppes_provider_last_org_name AS provider_last_name, prescriber. nppes_provider_first_name AS provider_first_name, prescriber.specialty_description AS provider_specialty, prescriber.nppes_provider_city AS provider_city, drug.drug_name, drug.opioid_drug_flag
FROM prescriber CROSS JOIN drug
WHERE specialty_description = 'Pain Management' AND opioid_drug_flag = 'Y' AND nppes_provider_city = 'NASHVILLE'
ORDER BY prescriber.npi ;
--Answer: table of providers who practice in Pain Management with prescription of opioids in Nashville

--7b
SELECT drug_name, npi, SUM (total_claim_count) AS total_claims
FROM prescriber CROSS JOIN drug
				LEFT JOIN prescription USING (npi, drug_name)
WHERE specialty_description = 'Pain Management' AND opioid_drug_flag = 'Y' AND nppes_provider_city = 'NASHVILLE'
GROUP BY drug_name, npi
ORDER BY total_claims DESC NULLS LAST ;
--Answer: table of drugs by npi and total_claims if any

--7c
SELECT drug_name, npi, 
	   COALESCE (SUM (total_claim_count), '0') AS total_claims
FROM prescriber CROSS JOIN drug
				LEFT JOIN prescription USING (npi, drug_name)
WHERE specialty_description = 'Pain Management' AND opioid_drug_flag = 'Y' AND nppes_provider_city = 'NASHVILLE'
GROUP BY drug_name, npi
ORDER BY npi ;
--Answer: same as 7b but missing values report as '0's