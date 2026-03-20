-- =============================================
-- CareNest: Enable RLS on ALL public tables
-- Run this in Supabase SQL Editor
-- =============================================

-- ============ 1. ENABLE RLS ON ALL TABLES ============

ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.caregiver_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.caregiver_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.caregiver_specializations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.caregiver_certifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.caregiver_languages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.caregiver_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.caregiver_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_allergies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_medical_conditions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_insurance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;


-- ============ 2. ADMINS TABLE ============

CREATE POLICY "Admins can view own record"
  ON public.admins FOR SELECT
  USING (auth.uid() = auth_id);


-- ============ 3. CAREGIVER PROFILES ============

CREATE POLICY "Anyone authenticated can view caregiver profiles"
  ON public.caregiver_profiles FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Caregivers can update own profile"
  ON public.caregiver_profiles FOR UPDATE
  USING (auth.uid() = auth_id);

CREATE POLICY "Caregivers can insert own profile"
  ON public.caregiver_profiles FOR INSERT
  WITH CHECK (auth.uid() = auth_id);


-- ============ 4. PATIENT PROFILES ============

CREATE POLICY "Authenticated users can view patient profiles"
  ON public.patient_profiles FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Patients can update own profile"
  ON public.patient_profiles FOR UPDATE
  USING (auth.uid() = auth_id);

CREATE POLICY "Patients can insert own profile"
  ON public.patient_profiles FOR INSERT
  WITH CHECK (auth.uid() = auth_id);


-- ============ 5. CAREGIVER APPLICATIONS ============

CREATE POLICY "Caregivers can view own applications"
  ON public.caregiver_applications FOR SELECT
  USING (auth.uid() IN (
    SELECT auth_id FROM public.caregiver_profiles WHERE id = caregiver_id
  ));

CREATE POLICY "Caregivers can insert applications"
  ON public.caregiver_applications FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');


-- ============ 6. BOOKINGS ============
-- patient_id and caregiver_id are INTEGER refs to profiles, not UUIDs
-- So we need to look up the profile to check auth_id

CREATE POLICY "Patients can view own bookings"
  ON public.bookings FOR SELECT
  USING (patient_id IN (
    SELECT id FROM public.patient_profiles WHERE auth_id = auth.uid()
  ));

CREATE POLICY "Caregivers can view assigned bookings"
  ON public.bookings FOR SELECT
  USING (caregiver_id IN (
    SELECT id FROM public.caregiver_profiles WHERE auth_id = auth.uid()
  ));

CREATE POLICY "Patients can create bookings"
  ON public.bookings FOR INSERT
  WITH CHECK (patient_id IN (
    SELECT id FROM public.patient_profiles WHERE auth_id = auth.uid()
  ));

CREATE POLICY "Caregivers can update assigned bookings"
  ON public.bookings FOR UPDATE
  USING (caregiver_id IN (
    SELECT id FROM public.caregiver_profiles WHERE auth_id = auth.uid()
  ));

CREATE POLICY "Patients can update own bookings"
  ON public.bookings FOR UPDATE
  USING (patient_id IN (
    SELECT id FROM public.patient_profiles WHERE auth_id = auth.uid()
  ));


-- ============ 7. CAREGIVER SUB-TABLES ============

-- Specializations
CREATE POLICY "Anyone can view specializations"
  ON public.caregiver_specializations FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Caregivers can manage own specializations"
  ON public.caregiver_specializations FOR ALL
  USING (caregiver_id IN (
    SELECT id FROM public.caregiver_profiles WHERE auth_id = auth.uid()
  ));

-- Certifications
CREATE POLICY "Anyone can view certifications"
  ON public.caregiver_certifications FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Caregivers can manage own certifications"
  ON public.caregiver_certifications FOR ALL
  USING (caregiver_id IN (
    SELECT id FROM public.caregiver_profiles WHERE auth_id = auth.uid()
  ));

-- Languages
CREATE POLICY "Anyone can view languages"
  ON public.caregiver_languages FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Caregivers can manage own languages"
  ON public.caregiver_languages FOR ALL
  USING (caregiver_id IN (
    SELECT id FROM public.caregiver_profiles WHERE auth_id = auth.uid()
  ));

-- Availability
CREATE POLICY "Anyone can view availability"
  ON public.caregiver_availability FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Caregivers can manage own availability"
  ON public.caregiver_availability FOR ALL
  USING (caregiver_id IN (
    SELECT id FROM public.caregiver_profiles WHERE auth_id = auth.uid()
  ));

-- Caregiver Documents
CREATE POLICY "Caregivers can view own documents"
  ON public.caregiver_documents FOR SELECT
  USING (caregiver_id IN (
    SELECT id FROM public.caregiver_profiles WHERE auth_id = auth.uid()
  ));

CREATE POLICY "Caregivers can upload own documents"
  ON public.caregiver_documents FOR INSERT
  WITH CHECK (caregiver_id IN (
    SELECT id FROM public.caregiver_profiles WHERE auth_id = auth.uid()
  ));


-- ============ 8. PATIENT SUB-TABLES ============

-- Patient Allergies
CREATE POLICY "Patients can manage own allergies"
  ON public.patient_allergies FOR ALL
  USING (patient_id IN (
    SELECT id FROM public.patient_profiles WHERE auth_id = auth.uid()
  ));

-- Patient Medical Conditions
CREATE POLICY "Patients can manage own medical conditions"
  ON public.patient_medical_conditions FOR ALL
  USING (patient_id IN (
    SELECT id FROM public.patient_profiles WHERE auth_id = auth.uid()
  ));

-- Patient Medications
CREATE POLICY "Patients can manage own medications"
  ON public.patient_medications FOR ALL
  USING (patient_id IN (
    SELECT id FROM public.patient_profiles WHERE auth_id = auth.uid()
  ));

-- Patient Emergency Contacts
CREATE POLICY "Patients can manage own emergency contacts"
  ON public.patient_emergency_contacts FOR ALL
  USING (patient_id IN (
    SELECT id FROM public.patient_profiles WHERE auth_id = auth.uid()
  ));

-- Patient Insurance
CREATE POLICY "Patients can manage own insurance"
  ON public.patient_insurance FOR ALL
  USING (patient_id IN (
    SELECT id FROM public.patient_profiles WHERE auth_id = auth.uid()
  ));

-- Patient Documents
CREATE POLICY "Patients can manage own documents"
  ON public.patient_documents FOR ALL
  USING (patient_id IN (
    SELECT id FROM public.patient_profiles WHERE auth_id = auth.uid()
  ));


-- ============ 9. NOTIFICATIONS ============

CREATE POLICY "Users can view own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_auth_id);

CREATE POLICY "Authenticated users can create notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update own notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_auth_id);


-- ============ 10. REVIEWS ============

CREATE POLICY "Anyone can view reviews"
  ON public.reviews FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Patients can create reviews"
  ON public.reviews FOR INSERT
  WITH CHECK (patient_id IN (
    SELECT id FROM public.patient_profiles WHERE auth_id = auth.uid()
  ));

CREATE POLICY "Patients can update own reviews"
  ON public.reviews FOR UPDATE
  USING (patient_id IN (
    SELECT id FROM public.patient_profiles WHERE auth_id = auth.uid()
  ));


-- ============ 11. FIX SECURITY DEFINER VIEW ============

DROP VIEW IF EXISTS public.all_users;
CREATE VIEW public.all_users
WITH (security_invoker = true)
AS
SELECT * FROM auth.users;


-- ============ DONE ============
-- Admin portal uses SERVICE ROLE KEY (bypasses RLS)
-- Mobile app uses ANON KEY + user auth (RLS applies)
