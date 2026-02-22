-- ═══════════════════════════════════════════════════════════════
-- MijnSanadome – Onboarding TESTDATA
-- Voer dit uit NA onboarding.sql EN onboarding-templates.sql
--
-- Dit maakt een testtraject aan voor de HUIDIGE ingelogde user.
-- ═══════════════════════════════════════════════════════════════

-- ─── Testtraject aanmaken voor je eigen account ───
-- Vervang '<JE_EMAIL>' met je eigen e-mailadres, of gebruik de
-- subquery-versie hieronder die automatisch de eerste user pakt.

-- Optie 1: Automatisch de eerste user pakken
DO $$
DECLARE
  v_user_id UUID;
  v_user_name TEXT;
  v_traject_id UUID;
  v_taak RECORD;
BEGIN
  -- Pak de eerste beschikbare user (of pas aan naar je eigen e-mail)
  SELECT id,
         COALESCE(raw_user_meta_data->>'full_name', raw_user_meta_data->>'name', email)
  INTO v_user_id, v_user_name
  FROM auth.users
  ORDER BY created_at ASC
  LIMIT 1;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Geen users gevonden in auth.users';
  END IF;

  RAISE NOTICE 'Testtraject aanmaken voor: % (%)', v_user_name, v_user_id;

  -- Traject aanmaken (start vandaag - 7 dagen = nu in week 2)
  INSERT INTO onboarding_trajecten (medewerker_id, naam, afdeling, startdatum, status, template_id, aangemaakt_door)
  VALUES (
    v_user_id,
    v_user_name,
    'Front Office',
    CURRENT_DATE - INTERVAL '7 days',   -- 7 dagen geleden gestart = nu in week 2
    'actief',
    '00000000-0000-0000-0000-000000000001',  -- Front Office Standaard template
    v_user_id
  )
  RETURNING id INTO v_traject_id;

  RAISE NOTICE 'Traject ID: %', v_traject_id;

  -- Week 1 taken als "voltooid" markeren (want die week is al voorbij)
  FOR v_taak IN
    SELECT id, titel FROM onboarding_taken
    WHERE template_id = '00000000-0000-0000-0000-000000000001'
    AND week_nr = 1
    ORDER BY volgorde
  LOOP
    INSERT INTO onboarding_voortgang (traject_id, taak_id, voltooid, voltooid_door, voltooid_naam, voltooid_op, notities)
    VALUES (
      v_traject_id,
      v_taak.id,
      true,
      v_user_id,
      v_user_name,
      CURRENT_TIMESTAMP - INTERVAL '5 days',
      NULL
    );
    RAISE NOTICE 'Week 1 taak afgetekend: %', v_taak.titel;
  END LOOP;

  -- Eerste 3 taken van week 2 ook als voltooid markeren
  FOR v_taak IN
    SELECT id, titel FROM onboarding_taken
    WHERE template_id = '00000000-0000-0000-0000-000000000001'
    AND week_nr = 2
    ORDER BY volgorde
    LIMIT 3
  LOOP
    INSERT INTO onboarding_voortgang (traject_id, taak_id, voltooid, voltooid_door, voltooid_naam, voltooid_op, notities)
    VALUES (
      v_traject_id,
      v_taak.id,
      true,
      v_user_id,
      v_user_name,
      CURRENT_TIMESTAMP - INTERVAL '1 day',
      'Goed gedaan, snelle leerling!'
    );
    RAISE NOTICE 'Week 2 taak afgetekend: %', v_taak.titel;
  END LOOP;

  -- Een paar notities toevoegen
  INSERT INTO onboarding_notities (traject_id, auteur_id, auteur_naam, inhoud, week_nr) VALUES
    (v_traject_id, v_user_id, v_user_name, 'Eerste week goed doorlopen. Medewerker leert snel en stelt goede vragen.', 1),
    (v_traject_id, v_user_id, v_user_name, 'Check-in procedure moet nog iets geoefend worden, rest gaat prima.', 2);

  RAISE NOTICE '✅ Testdata aangemaakt! Traject: % voor %', v_traject_id, v_user_name;
END;
$$;


-- ═══════════════════════════════════════════════════════════════
-- Optie 2: Voor een SPECIFIEKE user (uncomment en vul je e-mail in)
-- ═══════════════════════════════════════════════════════════════
/*
DO $$
DECLARE
  v_user_id UUID;
  v_traject_id UUID;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE email = 'jouw@email.com';

  INSERT INTO onboarding_trajecten (medewerker_id, naam, afdeling, startdatum, status, template_id)
  VALUES (v_user_id, 'Jouw Naam', 'Front Office', CURRENT_DATE - INTERVAL '7 days', 'actief', '00000000-0000-0000-0000-000000000001')
  RETURNING id INTO v_traject_id;

  RAISE NOTICE 'Traject aangemaakt: %', v_traject_id;
END;
$$;
*/
