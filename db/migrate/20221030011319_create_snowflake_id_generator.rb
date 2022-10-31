class CreateSnowflakeIdGenerator < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE SEQUENCE public.snowflake_id_seq
            START WITH 1
            INCREMENT BY 1
            MAXVALUE 1024
            CYCLE;

          CREATE OR REPLACE FUNCTION public.snowflake_id() RETURNS bigint LANGUAGE plpgsql AS $$
          DECLARE
            epoch bigint := 1288834974657;
            seq_id bigint;
            now bigint;

            -- Typically this would be an ID assigned to this database replica,
            -- but this is just a personal blog. We only have the one.
            worker_id int := 1;
            result bigint;
          BEGIN
            SELECT NEXTVAL('public.snowflake_id_seq') INTO seq_id;
            SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now;

            result := (now - epoch) << 22;
            result := result | (worker_id << 10);
            result := result | seq_id;

            return result;
          END;
          $$;
        SQL
      end

      dir.down do
        execute <<~SQL
          DROP FUNCTION public.snowflake_id();
          DROP SEQUENCE public.snowflake_id_seq;
        SQL
      end
    end
  end
end
