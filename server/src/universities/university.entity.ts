import { Column, Entity, PrimaryColumn } from 'typeorm';

@Entity('universities')
export class University {
  @PrimaryColumn({ type: 'uuid' })
  id: string;

  @Column({ name: 'name_th', type: 'varchar', length: 255, unique: true })
  nameTh: string;

  @Column({ type: 'text', array: true, default: () => "'{}'" })
  aliases: string[];
}
