CREATE OR REPLACE FUNCTION new_session(uid bigint) RETURNS json
AS $$
DECLARE
    retval json;
BEGIN
    WITH s AS(INSERT INTO public.session(user_id) VALUES(uid) RETURNING "token")
    SELECT to_json(usr) INTO retval FROM
        (SELECT "username", "email", (SELECT "token" from s), "bio", "image"
        FROM public.user
        WHERE user_id = uid
        LIMIT 1
      ) usr;
  
    RETURN (SELECT row_to_json(usr) FROM (SELECT retval AS "user") usr);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION register_user(raw text, OUT status_code smallint, OUT resp text)
AS $$
DECLARE
    usr json := raw::json->'user';
    uname text := usr->>'username';
    em text := usr->>'email';
    pw_plaintext text := usr->>'password';
    pw_salt text := gen_salt('bf', 8);
    encrypted_pw text := crypt(pw_plaintext, pw_salt);
    uid bigint;
BEGIN

	WITH inserted AS(
    INSERT INTO public.user(username, email, encrypted_password, password_salt)
        VALUES (uname, em, encrypted_pw, pw_salt)
        RETURNING user_id
  )
	SELECT new_session((SELECT user_id FROM inserted))::text INTO resp;

  SELECT 201 INTO status_code;
  -- TODO on exception (e.g. email or username in use), return a different status_code
END;                                                                                                               
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION login(raw text, OUT status_code smallint, OUT resp text)
AS $$
DECLARE
    usr json := raw::json->'user';
    em text := usr->>'email';
    pw_plaintext text := usr->>'password';
    uid bigint;
    retval json;
BEGIN
    SELECT "user_id" INTO uid
        FROM public.user AS u
        WHERE
          u.email = em AND
          u.encrypted_password = crypt(pw_plaintext, u.password_salt);
    
    SELECT (
      CASE WHEN uid IS NULL THEN
        403
      ELSE
        200
      END
    ) INTO status_code;

    SELECT (
      CASE WHEN uid IS NULL THEN
        '"Invalid email or password"'::text
      ELSE
        new_session(uid)::text
      END
    ) INTO resp;
END;
$$ LANGUAGE plpgsql;
