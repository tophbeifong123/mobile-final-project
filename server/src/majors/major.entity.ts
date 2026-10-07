import { Column, Entity, PrimaryColumn } from 'typeorm';

@Entity('majors')
export class Major {
  @PrimaryColumn({ type: 'uuid' })
  id: string;

  @Column({ name: 'name_th', type: 'varchar', length: 255, unique: true })
  nameTh: string;
}
