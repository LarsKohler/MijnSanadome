-- ═══════════════════════════════════════════════════════════════
-- MijnSanadome – Onboarding Templates Migratie
-- Voer dit uit NA het basis onboarding.sql script
-- ═══════════════════════════════════════════════════════════════

-- ─── 1. Templates tabel ───
CREATE TABLE IF NOT EXISTS onboarding_templates (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  naam            TEXT NOT NULL,
  omschrijving    TEXT,
  afdeling        TEXT NOT NULL DEFAULT 'Algemeen',
  actief          BOOLEAN NOT NULL DEFAULT true,
  aangemaakt_door UUID REFERENCES auth.users(id),
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ─── 2. Template_id toevoegen aan taken ───
ALTER TABLE onboarding_taken
  ADD COLUMN IF NOT EXISTS template_id UUID REFERENCES onboarding_templates(id) ON DELETE CASCADE;

-- ─── 3. Template_id toevoegen aan trajecten ───
ALTER TABLE onboarding_trajecten
  ADD COLUMN IF NOT EXISTS template_id UUID REFERENCES onboarding_templates(id);

-- ─── 4. Standaard template aanmaken & bestaande taken koppelen ───
INSERT INTO onboarding_templates (id, naam, omschrijving, afdeling, actief)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'Front Office Standaard',
  'Standaard 4-weken inwerkprogramma voor Front Office medewerkers.',
  'Front Office',
  true
);

-- Koppel bestaande taken aan de standaard template
UPDATE onboarding_taken
SET template_id = '00000000-0000-0000-0000-000000000001'
WHERE template_id IS NULL;

-- ─── 5. Extra template: Reserveringen ───
INSERT INTO onboarding_templates (id, naam, omschrijving, afdeling, actief)
VALUES (
  '00000000-0000-0000-0000-000000000002',
  'Reserveringen Standaard',
  'Inwerkprogramma gericht op reserveringen en revenue management.',
  'Reserveringen',
  true
);

-- Taken voor Reserveringen template
INSERT INTO onboarding_taken (template_id, week_nr, titel, omschrijving, afdeling, volgorde) VALUES
  ('00000000-0000-0000-0000-000000000002', 1, 'Welkomstgesprek & rondleiding',             'Kennismaking met het team, rondleiding door het hotel.',                       'Algemeen',       1),
  ('00000000-0000-0000-0000-000000000002', 1, 'Systemen & inloggegevens ontvangen',         'MijnSanadome, e-mail, PMS, boekingssystemen.',                                'Algemeen',       2),
  ('00000000-0000-0000-0000-000000000002', 1, 'Huisregels & veiligheidsprotocol',           'Brandveiligheid, ontruimingsplan, hygiëneregels.',                             'Algemeen',       3),
  ('00000000-0000-0000-0000-000000000002', 1, 'Introductie boekingssysteem',                'Opera/PMS omgeving, reserveringsschermen, zoekfuncties.',                      'Reserveringen',  4),
  ('00000000-0000-0000-0000-000000000002', 1, 'Kamertypes & tariefstructuur leren',         'Alle kamertypes, seizoenstarieven, BAR-tarieven, pakketten.',                  'Reserveringen',  5),
  ('00000000-0000-0000-0000-000000000002', 1, 'Telefoonetiquette reserveringen',            'Specifieke begroeting, beschikbaarheid checken, boekingsbevestiging.',          'Reserveringen',  6),
  ('00000000-0000-0000-0000-000000000002', 2, 'Reserveringen aanmaken & wijzigen',          'Nieuwe boekingen invoeren, datumwijzigingen, gastvoorkeuren.',                  'Reserveringen',  1),
  ('00000000-0000-0000-0000-000000000002', 2, 'Annuleringen & no-show beleid',              'Annuleringsvoorwaarden, kosten berekenen, uitzonderingen.',                    'Reserveringen',  2),
  ('00000000-0000-0000-0000-000000000002', 2, 'OTA-kanalen beheren',                        'Booking.com, Expedia — extranetten, beschikbaarheid, tarieven.',               'Reserveringen',  3),
  ('00000000-0000-0000-0000-000000000002', 2, 'Groepsreserveringen basis',                  'Groepsboeking, allotment, rooming lists.',                                      'Reserveringen',  4),
  ('00000000-0000-0000-0000-000000000002', 2, 'E-mail templates & correspondentie',        'Bevestigingsmails, offertes, pre-arrival mails.',                               'Reserveringen',  5),
  ('00000000-0000-0000-0000-000000000002', 2, 'Spa-arrangementen & pakketten',              'Alle arrangementen kennen, prijzen, beschikbaarheid.',                          'Reserveringen',  6),
  ('00000000-0000-0000-0000-000000000002', 3, 'Zelfstandig reserveringen verwerken',        'Zonder supervisie telefonische en online boekingen afhandelen.',                'Reserveringen',  1),
  ('00000000-0000-0000-0000-000000000002', 3, 'Revenue management basis',                   'Yield management, demand forecasting, tariefaanpassingen.',                     'Reserveringen',  2),
  ('00000000-0000-0000-0000-000000000002', 3, 'Upselling bij reserveringen',                'Kamerupgrade aanbieden, arrangementen toevoegen.',                              'Reserveringen',  3),
  ('00000000-0000-0000-0000-000000000002', 3, 'Klachtenafhandeling reserveringen',          'Omboekingen, prijsgaranties, escalatieprocedure.',                              'Reserveringen',  4),
  ('00000000-0000-0000-0000-000000000002', 3, 'Samenwerking Front Office & Housekeeping',   'Communicatie kamerstatus, speciale wensen doorgeven.',                          'Algemeen',       5),
  ('00000000-0000-0000-0000-000000000002', 4, 'Volledige dienst zelfstandig draaien',       'Complete shift reserveringen zonder begeleiding.',                              'Reserveringen',  1),
  ('00000000-0000-0000-0000-000000000002', 4, 'Rapportages & statistieken',                 'Bezettingsgraad, RevPAR, pickup rapportages draaien.',                          'Reserveringen',  2),
  ('00000000-0000-0000-0000-000000000002', 4, 'MICE & vergaderruimtes',                     'Zaalreserveringen, vergaderarrangementen, AV-faciliteiten.',                    'Reserveringen',  3),
  ('00000000-0000-0000-0000-000000000002', 4, 'Evaluatiegesprek met leidinggevende',        'Bespreking voortgang, sterke punten, aandachtspunten.',                         'Algemeen',       4),
  ('00000000-0000-0000-0000-000000000002', 4, 'Persoonlijk ontwikkelplan',                  'Doelen voor komende 3 maanden, gewenste trainingen.',                           'Algemeen',       5),
  ('00000000-0000-0000-0000-000000000002', 4, 'Kennistoets & certificaat',                  'Toets over systemen en procedures, onboarding afronden.',                       'Algemeen',       6);


-- ─── 6. RLS voor templates ───
ALTER TABLE onboarding_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Iedereen leest actieve templates"
  ON onboarding_templates FOR SELECT
  USING (true);

CREATE POLICY "Beheerders beheren templates"
  ON onboarding_templates FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM auth.users u
      WHERE u.id = auth.uid()
      AND (u.raw_user_meta_data->>'role')::text IN ('Manager', 'Assistent Manager', 'Senior Medewerker')
    )
  );

CREATE POLICY "Beheerders updaten templates"
  ON onboarding_templates FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM auth.users u
      WHERE u.id = auth.uid()
      AND (u.raw_user_meta_data->>'role')::text IN ('Manager', 'Assistent Manager', 'Senior Medewerker')
    )
  );

CREATE POLICY "Beheerders verwijderen templates"
  ON onboarding_templates FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM auth.users u
      WHERE u.id = auth.uid()
      AND (u.raw_user_meta_data->>'role')::text IN ('Manager', 'Assistent Manager')
    )
  );

-- Trigger voor updated_at
CREATE TRIGGER trg_templates_updated
  BEFORE UPDATE ON onboarding_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Index
CREATE INDEX IF NOT EXISTS idx_taken_template ON onboarding_taken(template_id);
CREATE INDEX IF NOT EXISTS idx_trajecten_template ON onboarding_trajecten(template_id);
