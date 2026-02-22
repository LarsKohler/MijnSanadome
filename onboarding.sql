-- ═══════════════════════════════════════════════════════════════
-- MijnSanadome – Onboarding Schema voor Supabase
-- ═══════════════════════════════════════════════════════════════

-- ─── 1. Onboarding Trajecten ───
-- Elk traject koppelt een nieuwe medewerker aan een 4-weken inwerkprogramma.
CREATE TABLE onboarding_trajecten (
  id             UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  medewerker_id  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  naam           TEXT NOT NULL,                          -- Naam van de medewerker
  afdeling       TEXT NOT NULL DEFAULT 'Front Office',   -- Front Office, Reserveringen, etc.
  startdatum     DATE NOT NULL,                          -- Eerste werkdag = start week 1
  einddatum      DATE GENERATED ALWAYS AS (startdatum + INTERVAL '28 days') STORED,
  status         TEXT NOT NULL DEFAULT 'actief'
                   CHECK (status IN ('actief', 'afgerond', 'gepauzeerd')),
  aangemaakt_door UUID REFERENCES auth.users(id),       -- Manager/senior die traject startte
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  updated_at     TIMESTAMPTZ DEFAULT NOW()
);

-- Index voor snel opzoeken per medewerker
CREATE INDEX idx_trajecten_medewerker ON onboarding_trajecten(medewerker_id);
CREATE INDEX idx_trajecten_status     ON onboarding_trajecten(status);


-- ─── 2. Onboarding Taken ───
-- Standaard taken per week. Dit is de "template" tabel.
CREATE TABLE onboarding_taken (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  week_nr     INTEGER NOT NULL CHECK (week_nr >= 1 AND week_nr <= 4),
  titel       TEXT NOT NULL,
  omschrijving TEXT,                                     -- Uitleg van de taak
  afdeling    TEXT NOT NULL DEFAULT 'Algemeen',           -- Welke afdeling(en) dit betreft
  volgorde    INTEGER NOT NULL DEFAULT 0,                 -- Sorteervolgorde binnen de week
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_taken_week ON onboarding_taken(week_nr, volgorde);


-- ─── 3. Traject Voortgang ───
-- Per medewerker-traject: welke taken zijn afgerond, door wie, met notities.
CREATE TABLE onboarding_voortgang (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  traject_id    UUID NOT NULL REFERENCES onboarding_trajecten(id) ON DELETE CASCADE,
  taak_id       UUID NOT NULL REFERENCES onboarding_taken(id) ON DELETE CASCADE,
  voltooid      BOOLEAN NOT NULL DEFAULT FALSE,
  voltooid_door UUID REFERENCES auth.users(id),          -- Senior/AM/Manager die aftekende
  voltooid_naam TEXT,                                     -- Naam van de aftekenaar (deniormalisatie)
  voltooid_op   TIMESTAMPTZ,                              -- Wanneer afgetekend
  notities      TEXT,                                     -- Optionele opmerkingen
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(traject_id, taak_id)
);

CREATE INDEX idx_voortgang_traject ON onboarding_voortgang(traject_id);


-- ─── 4. Onboarding Notities ───
-- Vrije notities per traject (losse opmerkingen van begeleiders).
CREATE TABLE onboarding_notities (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  traject_id   UUID NOT NULL REFERENCES onboarding_trajecten(id) ON DELETE CASCADE,
  auteur_id    UUID REFERENCES auth.users(id),
  auteur_naam  TEXT,
  inhoud       TEXT NOT NULL,
  week_nr      INTEGER CHECK (week_nr >= 1 AND week_nr <= 4),  -- NULL = algemeen
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notities_traject ON onboarding_notities(traject_id);


-- ═══════════════════════════════════════════════════════════════
-- Row Level Security (RLS)
-- ═══════════════════════════════════════════════════════════════

-- Trajecten
ALTER TABLE onboarding_trajecten ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Medewerker ziet eigen traject"
  ON onboarding_trajecten FOR SELECT
  USING (medewerker_id = auth.uid());

CREATE POLICY "Beheerders zien alle trajecten"
  ON onboarding_trajecten FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM auth.users u
      WHERE u.id = auth.uid()
      AND (u.raw_user_meta_data->>'role')::text IN ('Manager', 'Assistent Manager', 'Senior Medewerker')
    )
  );

CREATE POLICY "Beheerders kunnen trajecten aanmaken"
  ON onboarding_trajecten FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM auth.users u
      WHERE u.id = auth.uid()
      AND (u.raw_user_meta_data->>'role')::text IN ('Manager', 'Assistent Manager', 'Senior Medewerker')
    )
  );

CREATE POLICY "Beheerders kunnen trajecten updaten"
  ON onboarding_trajecten FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM auth.users u
      WHERE u.id = auth.uid()
      AND (u.raw_user_meta_data->>'role')::text IN ('Manager', 'Assistent Manager', 'Senior Medewerker')
    )
  );

-- Taken (template, iedereen mag lezen)
ALTER TABLE onboarding_taken ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Iedereen leest taken"
  ON onboarding_taken FOR SELECT
  USING (true);

CREATE POLICY "Beheerders beheren taken"
  ON onboarding_taken FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM auth.users u
      WHERE u.id = auth.uid()
      AND (u.raw_user_meta_data->>'role')::text IN ('Manager', 'Assistent Manager')
    )
  );

-- Voortgang
ALTER TABLE onboarding_voortgang ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Medewerker ziet eigen voortgang"
  ON onboarding_voortgang FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM onboarding_trajecten t
      WHERE t.id = onboarding_voortgang.traject_id
      AND t.medewerker_id = auth.uid()
    )
  );

CREATE POLICY "Beheerders zien alle voortgang"
  ON onboarding_voortgang FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM auth.users u
      WHERE u.id = auth.uid()
      AND (u.raw_user_meta_data->>'role')::text IN ('Manager', 'Assistent Manager', 'Senior Medewerker')
    )
  );

CREATE POLICY "Beheerders updaten voortgang"
  ON onboarding_voortgang FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM auth.users u
      WHERE u.id = auth.uid()
      AND (u.raw_user_meta_data->>'role')::text IN ('Manager', 'Assistent Manager', 'Senior Medewerker')
    )
  );

-- Notities
ALTER TABLE onboarding_notities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Medewerker ziet eigen notities"
  ON onboarding_notities FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM onboarding_trajecten t
      WHERE t.id = onboarding_notities.traject_id
      AND t.medewerker_id = auth.uid()
    )
  );

CREATE POLICY "Beheerders zien alle notities"
  ON onboarding_notities FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM auth.users u
      WHERE u.id = auth.uid()
      AND (u.raw_user_meta_data->>'role')::text IN ('Manager', 'Assistent Manager', 'Senior Medewerker')
    )
  );

CREATE POLICY "Beheerders schrijven notities"
  ON onboarding_notities FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM auth.users u
      WHERE u.id = auth.uid()
      AND (u.raw_user_meta_data->>'role')::text IN ('Manager', 'Assistent Manager', 'Senior Medewerker')
    )
  );


-- ═══════════════════════════════════════════════════════════════
-- Standaard taken invoegen (template)
-- ═══════════════════════════════════════════════════════════════

-- Week 1: Introductie & Basis
INSERT INTO onboarding_taken (week_nr, titel, omschrijving, afdeling, volgorde) VALUES
  (1, 'Welkomstgesprek & rondleiding',               'Kennismaking met het team, rondleiding door het hotel en spa.',                  'Algemeen',       1),
  (1, 'Systemen & inloggegevens ontvangen',           'MijnSanadome toegang, e-mail, PMS-systeem, sleutelpas.',                        'Algemeen',       2),
  (1, 'Huisregels & veiligheidsprotocol doorgenomen', 'Brandveiligheid, ontruimingsplan, EHBO-locaties, hygiëneregels.',               'Algemeen',       3),
  (1, 'Kledingvoorschriften & presentatie',           'Uniform ontvangen, dresscode, naambadje.',                                       'Algemeen',       4),
  (1, 'Kennismaking directe collega''s',              'Voorstellen aan teamleden van de eigen afdeling.',                                'Algemeen',       5),
  (1, 'Basistraining PMS-systeem',                    'Inloggen, reservering opzoeken, gastprofiel bekijken.',                           'Front Office',   6),
  (1, 'Telefoonetiquette & begroeting',               'Standaard begroeting, doorverbinden, berichten noteren.',                         'Algemeen',       7);

-- Week 2: Verdieping & Eerste Taken
INSERT INTO onboarding_taken (week_nr, titel, omschrijving, afdeling, volgorde) VALUES
  (2, 'Check-in procedure volledig doorlopen',        'Gast ontvangen, ID-controle, keycard aanmaken, uitleg faciliteiten.',             'Front Office',   1),
  (2, 'Check-out procedure doorlopen',                'Rekening controleren, minibar, feedback vragen, afscheid.',                       'Front Office',   2),
  (2, 'Reserveringen aanmaken & wijzigen',            'Nieuwe boeking invoeren, datumwijziging, kamertypes.',                            'Reserveringen',  3),
  (2, 'Kassatraining & betaalmethoden',               'PIN, creditcard, contant, facturatie, fooienbeleid.',                             'Front Office',   4),
  (2, 'Afhandeling klachten (basis)',                  'Luisteren, empathie tonen, oplossing bieden, escalatie.',                         'Algemeen',       5),
  (2, 'Spa-faciliteiten kennen',                      'Behandelingen, openingstijden, boekingssysteem spa.',                             'Algemeen',       6),
  (2, 'Ontbijtservice & F&B basiskennis',             'Ontbijttijden, allergieën, roomservice procedure.',                               'Algemeen',       7);

-- Week 3: Zelfstandigheid & Verdieping
INSERT INTO onboarding_taken (week_nr, titel, omschrijving, afdeling, volgorde) VALUES
  (3, 'Zelfstandig check-in/check-out uitvoeren',     'Onder supervisie zelfstandig gasten ontvangen en uitchecken.',                    'Front Office',   1),
  (3, 'Groepsreserveringen verwerken',                'Groepsboeking invoeren, rooming list, speciale wensen.',                          'Reserveringen',  2),
  (3, 'No-show & annuleringsbeleid toepassen',        'No-show registratie, annuleringsgeld, uitzonderingen.',                           'Reserveringen',  3),
  (3, 'VIP-gasten & loyaliteitsprogramma',            'VIP-herkenning, special touches, terugkerende gasten.',                           'Front Office',   4),
  (3, 'Samenwerking met Housekeeping',                'Kamerstatus, vroege check-in, late check-out coördinatie.',                       'Algemeen',       5),
  (3, 'Nachtaudit procedure (kennismaking)',          'Dagafsluiting, rapportages, nachtprocedures.',                                    'Front Office',   6),
  (3, 'Omgaan met noodsituaties',                     'Ziekmeldingen gasten, stroomuitval, waterschade.',                                'Algemeen',       7);

-- Week 4: Afronding & Evaluatie
INSERT INTO onboarding_taken (week_nr, titel, omschrijving, afdeling, volgorde) VALUES
  (4, 'Volledige dienst zelfstandig draaien',         'Complete shift van begin tot eind zonder directe begeleiding.',                    'Front Office',   1),
  (4, 'Upselling technieken toepassen',               'Kamerupgrade, spa-arrangementen, restaurant aanbevelen.',                         'Front Office',   2),
  (4, 'Revenue management basiskennis',               'Tariefstructuur, seizoenen, BAR-tarieven, OTA-kanalen.',                          'Reserveringen',  3),
  (4, 'Evaluatiegesprek met leidinggevende',          'Bespreking voortgang, sterke punten, aandachtspunten.',                           'Algemeen',       4),
  (4, 'Persoonlijk ontwikkelplan opstellen',          'Doelen voor komende 3 maanden, gewenste trainingen.',                              'Algemeen',       5),
  (4, 'Kennistoets afleggen',                         'Korte toets over systemen, procedures en hotelkennis.',                            'Algemeen',       6),
  (4, 'Onboarding afronden & certificaat',            'Officiële afronding, certificaat, welkom in het team!',                            'Algemeen',       7);


-- ═══════════════════════════════════════════════════════════════
-- Helper: trigger om updated_at automatisch bij te werken
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_trajecten_updated
  BEFORE UPDATE ON onboarding_trajecten
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_voortgang_updated
  BEFORE UPDATE ON onboarding_voortgang
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
