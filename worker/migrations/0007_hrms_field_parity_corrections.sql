-- Additive field-parity corrections based on hr/models.py (63 models).
-- Apply only after migrations 0001-0006 on the dedicated HRMS test database.
-- Existing scaffold columns are retained for compatibility; these columns restore
-- the principal Django model fields omitted by the initial schema drafts.
BEGIN;

ALTER TABLE hrms_departments ADD COLUMN IF NOT EXISTS manager_id BIGINT NULL REFERENCES hrms_employees(id) ON DELETE SET NULL;

ALTER TABLE hrms_employees ADD COLUMN IF NOT EXISTS user_id BIGINT NULL UNIQUE;
ALTER TABLE hrms_employees ADD COLUMN IF NOT EXISTS face_verified BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE hrms_employee_documents ADD COLUMN IF NOT EXISTS issue_date DATE NULL;
ALTER TABLE hrms_employee_documents ADD COLUMN IF NOT EXISTS expiry_date DATE NULL;

ALTER TABLE hrms_attendance_records ADD COLUMN IF NOT EXISTS face_verified BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE hrms_attendance_records ADD COLUMN IF NOT EXISTS face_provider_ref VARCHAR(180) NOT NULL DEFAULT '';
ALTER TABLE hrms_attendance_records ADD COLUMN IF NOT EXISTS device_fingerprint VARCHAR(255) NOT NULL DEFAULT '';

ALTER TABLE hrms_leave_requests ADD COLUMN IF NOT EXISTS reason TEXT NOT NULL DEFAULT '';

ALTER TABLE hrms_approval_requests ADD COLUMN IF NOT EXISTS requester_employee_id BIGINT NULL REFERENCES hrms_employees(id) ON DELETE SET NULL;
ALTER TABLE hrms_approval_requests ADD COLUMN IF NOT EXISTS request_number VARCHAR(80) NOT NULL DEFAULT '';
ALTER TABLE hrms_approval_requests ADD COLUMN IF NOT EXISTS current_step SMALLINT NOT NULL DEFAULT 1 CHECK (current_step >= 1);
ALTER TABLE hrms_approval_steps ADD COLUMN IF NOT EXISTS approver_employee_id BIGINT NULL REFERENCES hrms_employees(id) ON DELETE SET NULL;
ALTER TABLE hrms_approval_steps ADD COLUMN IF NOT EXISTS comment TEXT NOT NULL DEFAULT '';
ALTER TABLE hrms_approval_steps ADD COLUMN IF NOT EXISTS decided_at TIMESTAMPTZ NULL;

ALTER TABLE hrms_payroll_items ADD COLUMN IF NOT EXISTS allowances NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_payroll_items ADD COLUMN IF NOT EXISTS overtime NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_payroll_items ADD COLUMN IF NOT EXISTS deductions NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_payroll_items ADD COLUMN IF NOT EXISTS tax_and_insurance NUMERIC(12,2) NOT NULL DEFAULT 0;

ALTER TABLE hrms_leave_policies ADD COLUMN IF NOT EXISTS annual_entitlement_days NUMERIC(7,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_leave_policies ADD COLUMN IF NOT EXISTS carry_forward_limit_days NUMERIC(7,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_leave_policies ADD COLUMN IF NOT EXISTS paid BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE hrms_leave_policies ADD COLUMN IF NOT EXISTS requires_document BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE hrms_employee_leave_balances ADD COLUMN IF NOT EXISTS opening_days NUMERIC(7,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_employee_leave_balances ADD COLUMN IF NOT EXISTS accrued_days NUMERIC(7,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_employee_leave_balances ADD COLUMN IF NOT EXISTS adjusted_days NUMERIC(7,2) NOT NULL DEFAULT 0;

ALTER TABLE hrms_recruitment_candidates ADD COLUMN IF NOT EXISTS source VARCHAR(120) NOT NULL DEFAULT '';
ALTER TABLE hrms_recruitment_candidates ADD COLUMN IF NOT EXISTS expected_salary NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_recruitment_candidates ADD COLUMN IF NOT EXISTS hired_employee_id BIGINT NULL REFERENCES hrms_employees(id) ON DELETE SET NULL;

ALTER TABLE hrms_insurance_form_records ADD COLUMN IF NOT EXISTS attachment_object_key TEXT NOT NULL DEFAULT '';
ALTER TABLE hrms_internal_regulations ADD COLUMN IF NOT EXISTS document_object_key TEXT NOT NULL DEFAULT '';
ALTER TABLE hrms_disciplinary_actions ADD COLUMN IF NOT EXISTS payroll_deduction_id BIGINT NULL REFERENCES hrms_employee_deductions(id) ON DELETE SET NULL;

ALTER TABLE hrms_training_courses ADD COLUMN IF NOT EXISTS skills TEXT NOT NULL DEFAULT '';
ALTER TABLE hrms_employee_training ADD COLUMN IF NOT EXISTS score NUMERIC(7,2) NULL;
ALTER TABLE hrms_employee_training ADD COLUMN IF NOT EXISTS approval_request_id BIGINT NULL REFERENCES hrms_approval_requests(id) ON DELETE SET NULL;

ALTER TABLE hrms_employee_audit_events ADD COLUMN IF NOT EXISTS actor_user_id BIGINT NULL;
ALTER TABLE hrms_employee_audit_events ADD COLUMN IF NOT EXISTS event_type VARCHAR(100) NOT NULL DEFAULT '';
ALTER TABLE hrms_employee_audit_events ADD COLUMN IF NOT EXISTS object_type VARCHAR(100) NOT NULL DEFAULT '';
ALTER TABLE hrms_employee_audit_events ADD COLUMN IF NOT EXISTS object_id VARCHAR(100) NOT NULL DEFAULT '';
ALTER TABLE hrms_employee_audit_events ADD COLUMN IF NOT EXISTS before_data JSONB NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE hrms_employee_audit_events ADD COLUMN IF NOT EXISTS after_data JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE hrms_employee_requirements ADD COLUMN IF NOT EXISTS category VARCHAR(100) NOT NULL DEFAULT '';
ALTER TABLE hrms_employee_requirements ADD COLUMN IF NOT EXISTS required_by DATE NULL;
ALTER TABLE hrms_employee_requirements ADD COLUMN IF NOT EXISTS submitted_at DATE NULL;
ALTER TABLE hrms_employee_requirements ADD COLUMN IF NOT EXISTS verified_by_employee_id BIGINT NULL REFERENCES hrms_employees(id) ON DELETE SET NULL;
ALTER TABLE hrms_employee_requirements ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ NULL;
ALTER TABLE hrms_employee_requirements ADD COLUMN IF NOT EXISTS document_id BIGINT NULL REFERENCES hrms_employee_documents(id) ON DELETE SET NULL;

ALTER TABLE hrms_position_assignments ADD COLUMN IF NOT EXISTS status VARCHAR(30) NOT NULL DEFAULT 'active';
ALTER TABLE hrms_position_assignments ADD COLUMN IF NOT EXISTS acting_for_employee_id BIGINT NULL REFERENCES hrms_employees(id) ON DELETE SET NULL;
ALTER TABLE hrms_position_assignments ADD COLUMN IF NOT EXISTS approval_request_id BIGINT NULL REFERENCES hrms_approval_requests(id) ON DELETE SET NULL;

ALTER TABLE hrms_department_workforce_plans ADD COLUMN IF NOT EXISTS fiscal_year SMALLINT NULL;
ALTER TABLE hrms_department_workforce_plans ADD COLUMN IF NOT EXISTS minimum_headcount INTEGER NOT NULL DEFAULT 0;
ALTER TABLE hrms_department_workforce_plans ADD COLUMN IF NOT EXISTS maximum_headcount INTEGER NOT NULL DEFAULT 0;
ALTER TABLE hrms_department_workforce_plans ADD COLUMN IF NOT EXISTS approved_annual_payroll_budget NUMERIC(14,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_department_workforce_plans ADD COLUMN IF NOT EXISTS approved_monthly_payroll_budget NUMERIC(14,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_department_workforce_plans ADD COLUMN IF NOT EXISTS approved_by_employee_id BIGINT NULL REFERENCES hrms_employees(id) ON DELETE SET NULL;
ALTER TABLE hrms_department_workforce_plans ADD COLUMN IF NOT EXISTS approval_request_id BIGINT NULL REFERENCES hrms_approval_requests(id) ON DELETE SET NULL;

ALTER TABLE hrms_advance_policies ADD COLUMN IF NOT EXISTS maximum_salary_multiple NUMERIC(7,3) NOT NULL DEFAULT 0;
ALTER TABLE hrms_advance_policies ADD COLUMN IF NOT EXISTS maximum_active_advances SMALLINT NOT NULL DEFAULT 1;
ALTER TABLE hrms_advance_policies ADD COLUMN IF NOT EXISTS maximum_deduction_percent NUMERIC(5,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_advance_policies ADD COLUMN IF NOT EXISTS minimum_service_months SMALLINT NOT NULL DEFAULT 0;
ALTER TABLE hrms_employee_advances ADD COLUMN IF NOT EXISTS request_date DATE NULL;
ALTER TABLE hrms_employee_advances ADD COLUMN IF NOT EXISTS installment_amount NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_employee_advances ADD COLUMN IF NOT EXISTS remaining_balance NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_employee_advances ADD COLUMN IF NOT EXISTS installments_count SMALLINT NOT NULL DEFAULT 1;
ALTER TABLE hrms_employee_advances ADD COLUMN IF NOT EXISTS payroll_deduction_id BIGINT NULL REFERENCES hrms_employee_deductions(id) ON DELETE SET NULL;
ALTER TABLE hrms_employee_advances ADD COLUMN IF NOT EXISTS disbursed_at DATE NULL;

ALTER TABLE hrms_custody_assets ADD COLUMN IF NOT EXISTS acquisition_date DATE NULL;
ALTER TABLE hrms_custody_assets ADD COLUMN IF NOT EXISTS acquisition_cost NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_custody_assets ADD COLUMN IF NOT EXISTS current_value NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_custody_assets ADD COLUMN IF NOT EXISTS insured BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE hrms_custody_assets ADD COLUMN IF NOT EXISTS insurance_policy_number VARCHAR(120) NOT NULL DEFAULT '';
ALTER TABLE hrms_custody_assets ADD COLUMN IF NOT EXISTS insurer VARCHAR(180) NOT NULL DEFAULT '';
ALTER TABLE hrms_custody_assets ADD COLUMN IF NOT EXISTS insurance_start DATE NULL;
ALTER TABLE hrms_custody_assets ADD COLUMN IF NOT EXISTS insurance_end DATE NULL;
ALTER TABLE hrms_custody_assets ADD COLUMN IF NOT EXISTS insured_value NUMERIC(12,2) NOT NULL DEFAULT 0;

ALTER TABLE hrms_custody_assignments ADD COLUMN IF NOT EXISTS expected_return DATE NULL;
ALTER TABLE hrms_custody_assignments ADD COLUMN IF NOT EXISTS status VARCHAR(30) NOT NULL DEFAULT 'issued';
ALTER TABLE hrms_custody_assignments ADD COLUMN IF NOT EXISTS custody_document_object_key TEXT NOT NULL DEFAULT '';
ALTER TABLE hrms_custody_assignments ADD COLUMN IF NOT EXISTS approval_request_id BIGINT NULL REFERENCES hrms_approval_requests(id) ON DELETE SET NULL;

ALTER TABLE hrms_employee_contracts ADD COLUMN IF NOT EXISTS contract_number VARCHAR(100) NOT NULL DEFAULT '';
ALTER TABLE hrms_employee_contracts ADD COLUMN IF NOT EXISTS probation_end_date DATE NULL;
ALTER TABLE hrms_employee_contracts ADD COLUMN IF NOT EXISTS notice_days SMALLINT NOT NULL DEFAULT 30;
ALTER TABLE hrms_employee_contracts ADD COLUMN IF NOT EXISTS agreed_basic_salary NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_employee_contracts ADD COLUMN IF NOT EXISTS currency VARCHAR(3) NOT NULL DEFAULT 'EGP';
ALTER TABLE hrms_employee_contracts ADD COLUMN IF NOT EXISTS signed_document_object_key TEXT NOT NULL DEFAULT '';
ALTER TABLE hrms_employee_contracts ADD COLUMN IF NOT EXISTS renewed_from_id BIGINT NULL REFERENCES hrms_employee_contracts(id) ON DELETE SET NULL;
ALTER TABLE hrms_employee_contracts ADD COLUMN IF NOT EXISTS approved_by_employee_id BIGINT NULL REFERENCES hrms_employees(id) ON DELETE SET NULL;

ALTER TABLE hrms_employee_warnings ADD COLUMN IF NOT EXISTS warning_number VARCHAR(100) NOT NULL DEFAULT '';
ALTER TABLE hrms_employee_warnings ADD COLUMN IF NOT EXISTS issued_date DATE NULL;
ALTER TABLE hrms_employee_warnings ADD COLUMN IF NOT EXISTS severity VARCHAR(40) NOT NULL DEFAULT '';
ALTER TABLE hrms_employee_warnings ADD COLUMN IF NOT EXISTS policy_reference VARCHAR(180) NOT NULL DEFAULT '';
ALTER TABLE hrms_employee_warnings ADD COLUMN IF NOT EXISTS corrective_action TEXT NOT NULL DEFAULT '';
ALTER TABLE hrms_employee_warnings ADD COLUMN IF NOT EXISTS response_deadline DATE NULL;
ALTER TABLE hrms_employee_warnings ADD COLUMN IF NOT EXISTS employee_response TEXT NOT NULL DEFAULT '';
ALTER TABLE hrms_employee_warnings ADD COLUMN IF NOT EXISTS issued_by_employee_id BIGINT NULL REFERENCES hrms_employees(id) ON DELETE SET NULL;
ALTER TABLE hrms_employee_warnings ADD COLUMN IF NOT EXISTS attachment_object_key TEXT NOT NULL DEFAULT '';

ALTER TABLE hrms_employee_compensation_items ADD COLUMN IF NOT EXISTS kind VARCHAR(40) NOT NULL DEFAULT '';
ALTER TABLE hrms_employee_compensation_items ADD COLUMN IF NOT EXISTS name VARCHAR(160) NOT NULL DEFAULT '';
ALTER TABLE hrms_employee_compensation_items ADD COLUMN IF NOT EXISTS frequency VARCHAR(30) NOT NULL DEFAULT 'monthly';
ALTER TABLE hrms_employee_compensation_items ADD COLUMN IF NOT EXISTS taxable BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE hrms_employee_compensation_items ADD COLUMN IF NOT EXISTS insured BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE hrms_employee_compensation_items ADD COLUMN IF NOT EXISTS approved BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE hrms_employee_compensation_items ADD COLUMN IF NOT EXISTS approval_request_id BIGINT NULL REFERENCES hrms_approval_requests(id) ON DELETE SET NULL;
ALTER TABLE hrms_employee_compensation_items ADD COLUMN IF NOT EXISTS payroll_item_id BIGINT NULL REFERENCES hrms_payroll_items(id) ON DELETE SET NULL;

ALTER TABLE hrms_department_targets ADD COLUMN IF NOT EXISTS code VARCHAR(60) NOT NULL DEFAULT '';
ALTER TABLE hrms_department_targets ADD COLUMN IF NOT EXISTS name VARCHAR(180) NOT NULL DEFAULT '';
ALTER TABLE hrms_department_targets ADD COLUMN IF NOT EXISTS owner_employee_id BIGINT NULL REFERENCES hrms_employees(id) ON DELETE SET NULL;
ALTER TABLE hrms_department_targets ADD COLUMN IF NOT EXISTS fiscal_year SMALLINT NULL;
ALTER TABLE hrms_department_targets ADD COLUMN IF NOT EXISTS target_quantity NUMERIC(14,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_department_targets ADD COLUMN IF NOT EXISTS budget_amount NUMERIC(14,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_department_targets ADD COLUMN IF NOT EXISTS approval_request_id BIGINT NULL REFERENCES hrms_approval_requests(id) ON DELETE SET NULL;

ALTER TABLE hrms_target_achievements ADD COLUMN IF NOT EXISTS period_start DATE NULL;
ALTER TABLE hrms_target_achievements ADD COLUMN IF NOT EXISTS period_end DATE NULL;
ALTER TABLE hrms_target_achievements ADD COLUMN IF NOT EXISTS actual_quantity NUMERIC(14,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_target_achievements ADD COLUMN IF NOT EXISTS actual_cost NUMERIC(14,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_target_achievements ADD COLUMN IF NOT EXISTS source_reference VARCHAR(160) NOT NULL DEFAULT '';
ALTER TABLE hrms_target_achievements ADD COLUMN IF NOT EXISTS verified BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE hrms_offer_letters ADD COLUMN IF NOT EXISTS employee_id BIGINT NULL REFERENCES hrms_employees(id) ON DELETE SET NULL;
ALTER TABLE hrms_offer_letters ADD COLUMN IF NOT EXISTS offer_code VARCHAR(80) NOT NULL DEFAULT '';
ALTER TABLE hrms_offer_letters ADD COLUMN IF NOT EXISTS job_title VARCHAR(180) NOT NULL DEFAULT '';
ALTER TABLE hrms_offer_letters ADD COLUMN IF NOT EXISTS department_id BIGINT NULL REFERENCES hrms_departments(id) ON DELETE SET NULL;
ALTER TABLE hrms_offer_letters ADD COLUMN IF NOT EXISTS employment_type VARCHAR(60) NOT NULL DEFAULT '';
ALTER TABLE hrms_offer_letters ADD COLUMN IF NOT EXISTS proposed_start_date DATE NULL;
ALTER TABLE hrms_offer_letters ADD COLUMN IF NOT EXISTS offer_valid_until DATE NULL;
ALTER TABLE hrms_offer_letters ADD COLUMN IF NOT EXISTS basic_salary NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_offer_letters ADD COLUMN IF NOT EXISTS allowances NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_offer_letters ADD COLUMN IF NOT EXISTS bonus_terms TEXT NOT NULL DEFAULT '';
ALTER TABLE hrms_offer_letters ADD COLUMN IF NOT EXISTS benefits_summary TEXT NOT NULL DEFAULT '';
ALTER TABLE hrms_offer_letters ADD COLUMN IF NOT EXISTS probation_months SMALLINT NOT NULL DEFAULT 3;
ALTER TABLE hrms_offer_letters ADD COLUMN IF NOT EXISTS work_location VARCHAR(180) NOT NULL DEFAULT '';
ALTER TABLE hrms_offer_letters ADD COLUMN IF NOT EXISTS terms TEXT NOT NULL DEFAULT '';
ALTER TABLE hrms_offer_letters ADD COLUMN IF NOT EXISTS document_object_key TEXT NOT NULL DEFAULT '';
ALTER TABLE hrms_offer_letters ADD COLUMN IF NOT EXISTS approval_request_id BIGINT NULL REFERENCES hrms_approval_requests(id) ON DELETE SET NULL;
ALTER TABLE hrms_offer_letters ADD COLUMN IF NOT EXISTS sent_at TIMESTAMPTZ NULL;
ALTER TABLE hrms_offer_letters ADD COLUMN IF NOT EXISTS responded_at TIMESTAMPTZ NULL;

ALTER TABLE hrms_employee_dependents ADD COLUMN IF NOT EXISTS national_id_last4 VARCHAR(4) NOT NULL DEFAULT '';
ALTER TABLE hrms_employee_dependents ADD COLUMN IF NOT EXISTS eligible_for_medical BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE hrms_employee_dependents ADD COLUMN IF NOT EXISTS eligible_for_childcare BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE hrms_employee_dependents ADD COLUMN IF NOT EXISTS active BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE hrms_employee_medical_benefits ADD COLUMN IF NOT EXISTS kind VARCHAR(60) NOT NULL DEFAULT '';
ALTER TABLE hrms_employee_medical_benefits ADD COLUMN IF NOT EXISTS service_date DATE NULL;
ALTER TABLE hrms_employee_medical_benefits ADD COLUMN IF NOT EXISTS amount_claimed NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_employee_medical_benefits ADD COLUMN IF NOT EXISTS amount_approved NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_employee_medical_benefits ADD COLUMN IF NOT EXISTS currency VARCHAR(3) NOT NULL DEFAULT 'EGP';
ALTER TABLE hrms_employee_medical_benefits ADD COLUMN IF NOT EXISTS reference_number VARCHAR(120) NOT NULL DEFAULT '';
ALTER TABLE hrms_employee_medical_benefits ADD COLUMN IF NOT EXISTS attachment_object_key TEXT NOT NULL DEFAULT '';
ALTER TABLE hrms_employee_medical_benefits ADD COLUMN IF NOT EXISTS approval_request_id BIGINT NULL REFERENCES hrms_approval_requests(id) ON DELETE SET NULL;
ALTER TABLE hrms_employee_medical_benefits ADD COLUMN IF NOT EXISTS confidential_notes TEXT NOT NULL DEFAULT '';
ALTER TABLE hrms_employee_medical_benefits ADD COLUMN IF NOT EXISTS dependent_id BIGINT NULL REFERENCES hrms_employee_dependents(id) ON DELETE SET NULL;

ALTER TABLE hrms_employee_housing_assignments ADD COLUMN IF NOT EXISTS housing_code VARCHAR(80) NOT NULL DEFAULT '';
ALTER TABLE hrms_employee_housing_assignments ADD COLUMN IF NOT EXISTS address TEXT NOT NULL DEFAULT '';
ALTER TABLE hrms_employee_housing_assignments ADD COLUMN IF NOT EXISTS employee_contribution NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_employee_housing_assignments ADD COLUMN IF NOT EXISTS deposit_amount NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_employee_housing_assignments ADD COLUMN IF NOT EXISTS inventory_checklist TEXT NOT NULL DEFAULT '';
ALTER TABLE hrms_employee_housing_assignments ADD COLUMN IF NOT EXISTS handover_document_object_key TEXT NOT NULL DEFAULT '';
ALTER TABLE hrms_employee_housing_assignments ADD COLUMN IF NOT EXISTS approval_request_id BIGINT NULL REFERENCES hrms_approval_requests(id) ON DELETE SET NULL;

ALTER TABLE hrms_employee_childcare_benefits ADD COLUMN IF NOT EXISTS provider_name VARCHAR(180) NOT NULL DEFAULT '';
ALTER TABLE hrms_employee_childcare_benefits ADD COLUMN IF NOT EXISTS provider_reference VARCHAR(120) NOT NULL DEFAULT '';
ALTER TABLE hrms_employee_childcare_benefits ADD COLUMN IF NOT EXISTS monthly_fee NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_employee_childcare_benefits ADD COLUMN IF NOT EXISTS company_contribution NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_employee_childcare_benefits ADD COLUMN IF NOT EXISTS employee_contribution NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_employee_childcare_benefits ADD COLUMN IF NOT EXISTS approval_request_id BIGINT NULL REFERENCES hrms_approval_requests(id) ON DELETE SET NULL;

ALTER TABLE hrms_employee_benefit_enrollments ADD COLUMN IF NOT EXISTS company_cost NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_employee_benefit_enrollments ADD COLUMN IF NOT EXISTS employee_cost NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_employee_benefit_enrollments ADD COLUMN IF NOT EXISTS approval_request_id BIGINT NULL REFERENCES hrms_approval_requests(id) ON DELETE SET NULL;

ALTER TABLE hrms_attendance_device_configurations ADD COLUMN IF NOT EXISTS manufacturer VARCHAR(120) NOT NULL DEFAULT '';
ALTER TABLE hrms_attendance_device_configurations ADD COLUMN IF NOT EXISTS model_name VARCHAR(120) NOT NULL DEFAULT '';
ALTER TABLE hrms_attendance_device_configurations ADD COLUMN IF NOT EXISTS connection_type VARCHAR(60) NOT NULL DEFAULT '';
ALTER TABLE hrms_attendance_device_configurations ADD COLUMN IF NOT EXISTS ip_address INET NULL;
ALTER TABLE hrms_attendance_device_configurations ADD COLUMN IF NOT EXISTS port INTEGER NULL;
ALTER TABLE hrms_attendance_device_configurations ADD COLUMN IF NOT EXISTS protocol_or_software VARCHAR(180) NOT NULL DEFAULT '';
ALTER TABLE hrms_attendance_device_configurations ADD COLUMN IF NOT EXISTS external_device_id VARCHAR(180) NOT NULL DEFAULT '';
ALTER TABLE hrms_attendance_device_configurations ADD COLUMN IF NOT EXISTS enabled BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE hrms_regulation_rules ADD COLUMN IF NOT EXISTS rule_type VARCHAR(60) NOT NULL DEFAULT '';
ALTER TABLE hrms_regulation_rules ADD COLUMN IF NOT EXISTS scope VARCHAR(60) NOT NULL DEFAULT '';
ALTER TABLE hrms_regulation_rules ADD COLUMN IF NOT EXISTS source_type VARCHAR(60) NOT NULL DEFAULT '';
ALTER TABLE hrms_regulation_rules ADD COLUMN IF NOT EXISTS source_reference VARCHAR(180) NOT NULL DEFAULT '';
ALTER TABLE hrms_regulation_rules ADD COLUMN IF NOT EXISTS effective_from DATE NULL;
ALTER TABLE hrms_regulation_rules ADD COLUMN IF NOT EXISTS effective_to DATE NULL;
ALTER TABLE hrms_regulation_rules ADD COLUMN IF NOT EXISTS limit_value NUMERIC(12,2) NULL;
ALTER TABLE hrms_regulation_rules ADD COLUMN IF NOT EXISTS limit_unit VARCHAR(40) NOT NULL DEFAULT '';
ALTER TABLE hrms_regulation_rules ADD COLUMN IF NOT EXISTS requires_approval BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE hrms_regulation_rules ADD COLUMN IF NOT EXISTS document_object_key TEXT NOT NULL DEFAULT '';

ALTER TABLE hrms_hiring_document_templates ADD COLUMN IF NOT EXISTS category VARCHAR(100) NOT NULL DEFAULT '';
ALTER TABLE hrms_hiring_document_templates ADD COLUMN IF NOT EXISTS description TEXT NOT NULL DEFAULT '';
ALTER TABLE hrms_hiring_document_templates ADD COLUMN IF NOT EXISTS mandatory BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE hrms_hiring_document_templates ADD COLUMN IF NOT EXISTS applies_to VARCHAR(60) NOT NULL DEFAULT 'employee';
ALTER TABLE hrms_hiring_document_templates ADD COLUMN IF NOT EXISTS due_days_after_hire SMALLINT NOT NULL DEFAULT 0;
ALTER TABLE hrms_hiring_document_templates ADD COLUMN IF NOT EXISTS has_expiry BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE hrms_hiring_document_templates ADD COLUMN IF NOT EXISTS default_validity_months SMALLINT NULL;
ALTER TABLE hrms_hiring_document_templates ADD COLUMN IF NOT EXISTS alert_days_before_expiry SMALLINT NOT NULL DEFAULT 30;
ALTER TABLE hrms_hiring_document_templates ADD COLUMN IF NOT EXISTS requires_original BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE hrms_hiring_document_templates ADD COLUMN IF NOT EXISTS sort_order SMALLINT NOT NULL DEFAULT 0;

ALTER TABLE hrms_record_attachments ADD COLUMN IF NOT EXISTS category VARCHAR(100) NOT NULL DEFAULT '';
ALTER TABLE hrms_record_attachments ADD COLUMN IF NOT EXISTS issue_date DATE NULL;
ALTER TABLE hrms_record_attachments ADD COLUMN IF NOT EXISTS expiry_date DATE NULL;
ALTER TABLE hrms_record_attachments ADD COLUMN IF NOT EXISTS notes TEXT NOT NULL DEFAULT '';
ALTER TABLE hrms_record_attachments ADD COLUMN IF NOT EXISTS uploaded_by_ref VARCHAR(160) NOT NULL DEFAULT '';

ALTER TABLE hrms_recruitment_interviews ADD COLUMN IF NOT EXISTS stage VARCHAR(80) NOT NULL DEFAULT '';
ALTER TABLE hrms_recruitment_interviews ADD COLUMN IF NOT EXISTS interviewer_employee_id BIGINT NULL REFERENCES hrms_employees(id) ON DELETE SET NULL;
ALTER TABLE hrms_recruitment_interviews ADD COLUMN IF NOT EXISTS location_or_link VARCHAR(300) NOT NULL DEFAULT '';
ALTER TABLE hrms_recruitment_interviews ADD COLUMN IF NOT EXISTS earned_score NUMERIC(7,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_recruitment_interviews ADD COLUMN IF NOT EXISTS maximum_score NUMERIC(7,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_recruitment_interviews ADD COLUMN IF NOT EXISTS score_percent NUMERIC(5,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_recruitment_interviews ADD COLUMN IF NOT EXISTS recommendation VARCHAR(60) NOT NULL DEFAULT '';
ALTER TABLE hrms_recruitment_interviews ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ NULL;

ALTER TABLE hrms_interview_criteria ADD COLUMN IF NOT EXISTS interview_id BIGINT NULL REFERENCES hrms_recruitment_interviews(id) ON DELETE CASCADE;
ALTER TABLE hrms_interview_criteria ADD COLUMN IF NOT EXISTS question TEXT NOT NULL DEFAULT '';
ALTER TABLE hrms_interview_criteria ADD COLUMN IF NOT EXISTS maximum_score NUMERIC(7,2) NOT NULL DEFAULT 0;
ALTER TABLE hrms_interview_criteria ADD COLUMN IF NOT EXISTS sort_order SMALLINT NOT NULL DEFAULT 0;

ALTER TABLE hrms_interview_evaluations ADD COLUMN IF NOT EXISTS answer_notes TEXT NOT NULL DEFAULT '';
ALTER TABLE hrms_interview_evaluations ADD COLUMN IF NOT EXISTS evaluated_at TIMESTAMPTZ NULL;

ALTER TABLE hrms_career_development_plans ADD COLUMN IF NOT EXISTS objective TEXT NOT NULL DEFAULT '';
ALTER TABLE hrms_career_development_plans ADD COLUMN IF NOT EXISTS actions TEXT NOT NULL DEFAULT '';
ALTER TABLE hrms_career_development_plans ADD COLUMN IF NOT EXISTS owner_employee_id BIGINT NULL REFERENCES hrms_employees(id) ON DELETE SET NULL;
ALTER TABLE hrms_career_development_plans ADD COLUMN IF NOT EXISTS progress_percent SMALLINT NOT NULL DEFAULT 0 CHECK (progress_percent BETWEEN 0 AND 100);
ALTER TABLE hrms_career_development_plans ADD COLUMN IF NOT EXISTS review_notes TEXT NOT NULL DEFAULT '';

ALTER TABLE hrms_succession_plans ADD COLUMN IF NOT EXISTS development_needs TEXT NOT NULL DEFAULT '';
ALTER TABLE hrms_succession_plans ADD COLUMN IF NOT EXISTS risk_notes TEXT NOT NULL DEFAULT '';
ALTER TABLE hrms_succession_plans ADD COLUMN IF NOT EXISTS reviewed_by_employee_id BIGINT NULL REFERENCES hrms_employees(id) ON DELETE SET NULL;
ALTER TABLE hrms_succession_plans ADD COLUMN IF NOT EXISTS reviewed_at DATE NULL;
ALTER TABLE hrms_succession_plans ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE hrms_employee_of_month_settings ADD COLUMN IF NOT EXISTS performance_weight NUMERIC(5,2) NOT NULL DEFAULT 40;
ALTER TABLE hrms_employee_of_month_settings ADD COLUMN IF NOT EXISTS appearance_weight NUMERIC(5,2) NOT NULL DEFAULT 10;
ALTER TABLE hrms_employee_of_month_settings ADD COLUMN IF NOT EXISTS behavior_weight NUMERIC(5,2) NOT NULL DEFAULT 25;
ALTER TABLE hrms_employee_of_month_settings ADD COLUMN IF NOT EXISTS commitment_weight NUMERIC(5,2) NOT NULL DEFAULT 25;
ALTER TABLE hrms_employee_of_month_settings ADD COLUMN IF NOT EXISTS minimum_reviews SMALLINT NOT NULL DEFAULT 1;

ALTER TABLE hrms_employee_fund_policies ADD COLUMN IF NOT EXISTS monthly_deduction_amount NUMERIC(12,2) NOT NULL DEFAULT 0;

ALTER TABLE hrms_employee_association_turns ADD COLUMN IF NOT EXISTS actual_paid_amount NUMERIC(12,2) NULL;

ALTER TABLE hrms_employee_emergency_claims ADD COLUMN IF NOT EXISTS reviewer_employee_id BIGINT NULL REFERENCES hrms_employees(id) ON DELETE SET NULL;
ALTER TABLE hrms_employee_emergency_claims ADD COLUMN IF NOT EXISTS attachment_object_key TEXT NOT NULL DEFAULT '';

INSERT INTO hrms_schema_migrations(version)
VALUES ('0007_hrms_field_parity_corrections')
ON CONFLICT (version) DO NOTHING;

COMMIT;
