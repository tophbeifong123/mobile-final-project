import { Column, Entity, PrimaryColumn } from 'typeorm';

@Entity('provinces')
export class Province {
  @PrimaryColumn({ type: 'smallint' })
  id: number;

  @Column({ name: 'name_th', type: 'varchar', length: 100, unique: true })
  nameTh: string;

  @Column({ type: 'text', array: true, default: '{}' })
  aliases: string[];

  @Column({ name: 'center_latitude', type: 'double precision' })
  centerLatitude: number;

  @Column({ name: 'center_longitude', type: 'double precision' })
  centerLongitude: number;
}
