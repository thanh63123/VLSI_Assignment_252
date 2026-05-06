module iopads( swack, swcontrol, lscontrol,
               tdigit, tdigit_flag,
               reset, int, tdsp_port_out, tdsp_port_in,
	       scan_en, test_mode, scan_clk,
               spi_data, spi_fs,
	       refclk, vcop, vcom, pllrst, ibias,
               swackI, swcontrolI, lscontrolI,
               tdigitO, tdigit_flagO,
               resetI, intI, tdsp_portO, tdsp_portI,
	       scan_enI, test_modeI, scan_clkI,
               spi_dataI, spi_fsI,
	       refclkI, vcopO, vcomO, pllrstI, ibiasI
	       );

   input  swackI, swcontrol, lscontrol;
   output swack, swcontrolI, lscontrolI;

   output  [7:0] tdigit ;
   output [15:0] tdsp_port_out ;

   input  [15:0] tdsp_port_in ;

   output tdigit_flag	,
          vcop		,
          vcom ;

   input  reset		,
          int		,
          scan_en	,
          scan_clk	,
          test_mode	,
          spi_data	,
          spi_fs	,
          refclk	,
          pllrst	,
          ibias ;

   input   [7:0] tdigitO ;
   input  [15:0] tdsp_portO ;

   output [15:0] tdsp_portI ;

   input  tdigit_flagO	,
          vcopO		,
          vcomO ;

   output resetI	,
          intI		,
          scan_enI	,
          scan_clkI	,
          test_modeI	,
          spi_dataI	,
          spi_fsI	,
          refclkI	,
          pllrstI	,
          ibiasI ;

/* Power and Ground cells should be added through FE ioc file */
/*   PVSS1DGZ  Pvss0( );  */
/*   PVSS1DGZ  Pvss1( );  */
/*   PVSS1DGZ  Pvss2( );  */
/*   PVSS1DGZ  Pvss3( );  */
/*   PVDD1DGZ  Pvdd0( );  */
/*   PVDD1DGZ  Pvdd1( );  */
/*   PVDD1DGZ  Pvdd2( );  */
/*   PVDD1DGZ  Pvdd3( );  */
/*   PVDD1DGZ  Pavdd0( );  */
/*   PVSS1DGZ  Pavss0( );  */
/*   PCORNERDG Pcornerul( );  */
/*   PCORNERDG Pcornerur( );  */
/*   PCORNERDG Pcornerll( );  */
/*   PCORNERDG Pcornerlr( );  */


/*  ADDED for Low Power 90nm */
/* Example


OUTPUT pads
ex.   OUTPAD_8  uHBURST0     ( .PADO (HBURSTX[0]),     .PADI (sHBURST[0]));

   PDB02DGZ  uHBURST0 (.I (sHBURST[0]), .OEN (1'b0), .PAD (HBURSTX[0]), .C ());

*/
   PDB02DGZ  Ptdspop15(.I(tdsp_portO[15]), .OEN (1'b0), .PAD(tdsp_port_out[15]), .C ());

   PDB02DGZ  Ptdspop14(.I(tdsp_portO[14]), .OEN (1'b0), .PAD(tdsp_port_out[14]), .C ());

   PDB02DGZ  Ptdspop13(.I(tdsp_portO[13]), .OEN (1'b0), .PAD(tdsp_port_out[13]), .C ());

   PDB02DGZ  Ptdspop12(.I(tdsp_portO[12]), .OEN (1'b0), .PAD(tdsp_port_out[12]), .C ());

   PDB02DGZ  Ptdspop11(.I(tdsp_portO[11]), .OEN (1'b0), .PAD(tdsp_port_out[11]), .C ());

   PDB02DGZ  Ptdspop10(.I(tdsp_portO[10]), .OEN (1'b0), .PAD(tdsp_port_out[10]), .C ());

   PDB02DGZ  Ptdspop09(.I(tdsp_portO[9]), .OEN (1'b0), .PAD(tdsp_port_out[9]), .C ());

   PDB02DGZ  Ptdspop08(.I(tdsp_portO[8]), .OEN (1'b0), .PAD(tdsp_port_out[8]), .C ());

   PDB02DGZ  Ptdspop07(.I(tdsp_portO[7]), .OEN (1'b0), .PAD(tdsp_port_out[7]), .C ());

   PDB02DGZ  Ptdspop06(.I(tdsp_portO[6]), .OEN (1'b0), .PAD(tdsp_port_out[6]), .C ());

   PDB02DGZ  Ptdspop05(.I(tdsp_portO[5]), .OEN (1'b0), .PAD(tdsp_port_out[5]), .C ());

   PDB02DGZ  Ptdspop04(.I(tdsp_portO[4]), .OEN (1'b0), .PAD(tdsp_port_out[4]), .C ());

   PDB02DGZ  Ptdspop03(.I(tdsp_portO[3]), .OEN (1'b0), .PAD(tdsp_port_out[3]), .C ());

   PDB02DGZ  Ptdspop02(.I(tdsp_portO[2]), .OEN (1'b0), .PAD(tdsp_port_out[2]), .C ());

   PDB02DGZ  Ptdspop01(.I(tdsp_portO[1]), .OEN (1'b0), .PAD(tdsp_port_out[1]), .C ());

   PDB02DGZ  Ptdspop00(.I(tdsp_portO[0]), .OEN (1'b0), .PAD(tdsp_port_out[0]), .C ());

   PDB02DGZ  Ptdigfgop(.I(tdigit_flagO), .OEN (1'b0), .PAD(tdigit_flag), .C ());

   PDB02DGZ  Ptdigop7( .I(tdigitO[7]),	 .OEN (1'b0), .PAD(tdigit[7]), .C ());

   PDB02DGZ  Ptdigop6( .I(tdigitO[6]),	 .OEN (1'b0), .PAD(tdigit[6]), .C ());

   PDB02DGZ  Ptdigop5( .I(tdigitO[5]),	 .OEN (1'b0), .PAD(tdigit[5]), .C ());

   PDB02DGZ  Ptdigop4( .I(tdigitO[4]),	 .OEN (1'b0), .PAD(tdigit[4]), .C ());

   PDB02DGZ  Ptdigop3( .I(tdigitO[3]),	 .OEN (1'b0), .PAD(tdigit[3]), .C ());

   PDB02DGZ  Ptdigop2( .I(tdigitO[2]),	 .OEN (1'b0), .PAD(tdigit[2]), .C ());

   PDB02DGZ  Ptdigop1( .I(tdigitO[1]),	 .OEN (1'b0), .PAD(tdigit[1]), .C ());

   PDB02DGZ  Ptdigop0( .I(tdigitO[0]),	 .OEN (1'b0), .PAD(tdigit[0]), .C ());

   PDB02DGZ  Pvcopop(  .I(vcopO),	 .OEN (1'b0), .PAD(vcop), .C ());

   PDB02DGZ  Pvcomop(  .I(vcomO),	 .OEN (1'b0), .PAD(vcom), .C ());
   
   PDB02DGZ  Pswack(   .I(swackI),      .OEN (1'b0), .PAD(swack), .C ());

/*  Example
INPUT pades
   PDB02DGZ  uHRDATA0 (.I (1'b0), .OEN (1'b1), .PAD (HRDATAX[0]), .C (sHRDATA[0]));
*/

   PDB02DGZ    Plscontrol(.I (1'b0), .OEN (1'b1), .PAD(lscontrol), .C(lscontrolI));

   PDB02DGZ    Pswcontrol(.I (1'b0), .OEN (1'b1), .PAD(swcontrol), .C(swcontrolI));

   PDB02DGZ    Ptdspip15(.I (1'b0), .OEN (1'b1), .PAD(tdsp_port_in[15]), .C(tdsp_portI[15]));

   PDB02DGZ    Ptdspip14(.I (1'b0), .OEN (1'b1), .PAD(tdsp_port_in[14]), .C(tdsp_portI[14]));

   PDB02DGZ    Ptdspip13(.I (1'b0), .OEN (1'b1), .PAD(tdsp_port_in[13]), .C(tdsp_portI[13]));

   PDB02DGZ    Ptdspip12(.I (1'b0), .OEN (1'b1), .PAD(tdsp_port_in[12]), .C(tdsp_portI[12]));

   PDB02DGZ    Ptdspip11(.I (1'b0), .OEN (1'b1), .PAD(tdsp_port_in[11]), .C(tdsp_portI[11]));

   PDB02DGZ    Ptdspip10(.I (1'b0), .OEN (1'b1), .PAD(tdsp_port_in[10]), .C(tdsp_portI[10]));

   PDB02DGZ    Ptdspip09(.I (1'b0), .OEN (1'b1), .PAD(tdsp_port_in[9]), .C(tdsp_portI[9]));

   PDB02DGZ    Ptdspip08(.I (1'b0), .OEN (1'b1), .PAD(tdsp_port_in[8]), .C(tdsp_portI[8]));

   PDB02DGZ    Ptdspip07(.I (1'b0), .OEN (1'b1), .PAD(tdsp_port_in[7]), .C(tdsp_portI[7]));

   PDB02DGZ    Ptdspip06(.I (1'b0), .OEN (1'b1), .PAD(tdsp_port_in[6]), .C(tdsp_portI[6]));

   PDB02DGZ    Ptdspip05(.I (1'b0), .OEN (1'b1), .PAD(tdsp_port_in[5]), .C(tdsp_portI[5]));

   PDB02DGZ    Ptdspip04(.I (1'b0), .OEN (1'b1), .PAD(tdsp_port_in[4]), .C(tdsp_portI[4]));

   PDB02DGZ    Ptdspip03(.I (1'b0), .OEN (1'b1), .PAD(tdsp_port_in[3]), .C(tdsp_portI[3]));

   PDB02DGZ    Ptdspip02(.I (1'b0), .OEN (1'b1), .PAD(tdsp_port_in[2]), .C(tdsp_portI[2]));

   PDB02DGZ    Ptdspip01(.I (1'b0), .OEN (1'b1), .PAD(tdsp_port_in[1]), .C(tdsp_portI[1]));

   PDB02DGZ    Ptdspip00(.I (1'b0), .OEN (1'b1), .PAD(tdsp_port_in[0]), .C(tdsp_portI[0]));

   PDB02DGZ    Pscanenip(.I (1'b0), .OEN (1'b1), .PAD(scan_en), .C(scan_enI));

   PDB02DGZ    Pscanckip(.I (1'b0), .OEN (1'b1), .PAD(scan_clk), .C(scan_clkI));

   PDB02DGZ    Ptestmdip(.I (1'b0), .OEN (1'b1), .PAD(test_mode), .C(test_modeI));

   PDB02DGZ    Pspifsip( .I (1'b0), .OEN (1'b1), .PAD(spi_fs), .C(spi_fsI));

   PDB02DGZ    Pspidip(  .I (1'b0), .OEN (1'b1), .PAD(spi_data), .C(spi_dataI));

   PDB02DGZ    Presetip( .I (1'b0), .OEN (1'b1), .PAD(reset), .C(resetI));

   PDB02DGZ    Pintip(   .I (1'b0), .OEN (1'b1), .PAD(int), .C(intI));

   PDB02DGZ    Prefclkip(.I (1'b0), .OEN (1'b1), .PAD(refclk), .C(refclkI));

   PDB02DGZ    Ppllrstip(.I (1'b0), .OEN (1'b1), .PAD(pllrst), .C(pllrstI));

   PDB02DGZ    Pibiasip( .I (1'b0), .OEN (1'b1), .PAD(ibias), .C(ibiasI));

endmodule 
