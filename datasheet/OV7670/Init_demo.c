// register configure for rgb_565_qvga_25fps
static void init_rgb565_qvga_25fps_new(void)
{
	sensor_write_reg(0x12, 0x80);
	udelay(20000);
	sensor_write_reg(0x11, 0x80);
	sensor_write_reg(0x92, 0x7f);
	sensor_write_reg(0x93, 0x00);
	sensor_write_reg(0x9d, 0x9e);
	sensor_write_reg(0x3b, 0x0a);
	sensor_write_reg(0x13, 0xf2);
	sensor_write_reg(0x10, 0x00);
	sensor_write_reg(0x00, 0x00);
	sensor_write_reg(0x01, 0x80);
	sensor_write_reg(0x02, 0x80);
	sensor_write_reg(0x13, 0xd7);
	//
	sensor_write_reg(0x12, 0x14);
	sensor_write_reg(0x04, 0x00);
	sensor_write_reg(0x18, 0x4b);
	sensor_write_reg(0x17, 0x23);
	sensor_write_reg(0x32, 0xbf);
	sensor_write_reg(0x19, 0x02);
	sensor_write_reg(0x1a, 0x7a);
	sensor_write_reg(0x03, 0x00);
	//
	sensor_write_reg(0x0e, 0x84);
	sensor_write_reg(0x0f, 0x62);
	sensor_write_reg(0x15, 0x02);
	sensor_write_reg(0x16, 0x02);
	sensor_write_reg(0x1b, 0x01);
	sensor_write_reg(0x1e, 0x01);
	sensor_write_reg(0x29, 0x3c);
	sensor_write_reg(0x33, 0x00);
	sensor_write_reg(0x34, 0x07);
	sensor_write_reg(0x35, 0x84);
	sensor_write_reg(0x36, 0x00);
	sensor_write_reg(0x38, 0x13);
	sensor_write_reg(0x39, 0x43);
	sensor_write_reg(0x3a, 0x00);
	sensor_write_reg(0x3c, 0x6c);
	sensor_write_reg(0x3d, 0x90);
	sensor_write_reg(0x3f, 0x29);
	sensor_write_reg(0x40, 0xd1);
	sensor_write_reg(0x41, 0x20);
	sensor_write_reg(0x6b, 0x0a);
	sensor_write_reg(0xa1, 0xc8);
	//
	sensor_write_reg(0x69, 0x80);
	sensor_write_reg(0x43, 0xf0);
	sensor_write_reg(0x44, 0x10);
	sensor_write_reg(0x45, 0x78);
	sensor_write_reg(0x46, 0xa8);
	sensor_write_reg(0x47, 0x60);
	sensor_write_reg(0x48, 0x80);
	sensor_write_reg(0x59, 0xba);
	sensor_write_reg(0x5a, 0x9a);
	sensor_write_reg(0x5b, 0x22);
	sensor_write_reg(0x5c, 0xb9);
	sensor_write_reg(0x5d, 0x9b);
	sensor_write_reg(0x5e, 0x10);
	sensor_write_reg(0x5f, 0xe0);
	sensor_write_reg(0x60, 0x85);
	sensor_write_reg(0x61, 0x60);
	sensor_write_reg(0x9f, 0x9d);
	sensor_write_reg(0xa0, 0xa0);
	//
	sensor_write_reg(0x4f, 0xae);
	sensor_write_reg(0x50, 0x26);
	sensor_write_reg(0x51, 0x08);
	sensor_write_reg(0x52, 0x1a);
	sensor_write_reg(0x53, 0xa9);
	sensor_write_reg(0x54, 0x0f);
	sensor_write_reg(0x55, 0x05);
	sensor_write_reg(0x56, 0x46);
	sensor_write_reg(0x57, 0xcb);
	sensor_write_reg(0x58, 0x77);
	//
	sensor_write_reg(0x8b, 0xcc);
	sensor_write_reg(0x8c, 0xcc);
	sensor_write_reg(0x8d, 0xcf);
	//
	sensor_write_reg(0x6c, 0x40);
	sensor_write_reg(0x6d, 0x30);
	sensor_write_reg(0x6e, 0x4b);
	sensor_write_reg(0x6f, 0x60);
	sensor_write_reg(0x70, 0x70);
	sensor_write_reg(0x71, 0x70);
	sensor_write_reg(0x72, 0x70);
	sensor_write_reg(0x73, 0x70);
	sensor_write_reg(0x74, 0x60);
	sensor_write_reg(0x75, 0x60);
	sensor_write_reg(0x76, 0x50);
	sensor_write_reg(0x77, 0x48);
	sensor_write_reg(0x78, 0x3a);
	sensor_write_reg(0x79, 0x2e);
	sensor_write_reg(0x7a, 0x28);
	sensor_write_reg(0x7b, 0x22);
	sensor_write_reg(0x7c, 0x04);
	sensor_write_reg(0x7d, 0x07);
	sensor_write_reg(0x7e, 0x10);
	sensor_write_reg(0x7f, 0x28);
	sensor_write_reg(0x80, 0x36);
	sensor_write_reg(0x81, 0x44);
	sensor_write_reg(0x82, 0x52);
	sensor_write_reg(0x83, 0x60);
	sensor_write_reg(0x84, 0x6c);
	sensor_write_reg(0x85, 0x78);
	sensor_write_reg(0x86, 0x8c);
	sensor_write_reg(0x87, 0x9e);
	sensor_write_reg(0x88, 0xbb);
	sensor_write_reg(0x89, 0xd2);
	sensor_write_reg(0x8a, 0xe6);
	//
	sensor_write_reg(0x14, 0x2e);
	sensor_write_reg(0x24, 0xb8);
	sensor_write_reg(0x25, 0xa8);
}