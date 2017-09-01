unit RunErr;
interface
    function GetErrorStr(code:byte):string;

implementation
     function GetErrorStr(code:byte):string;
     begin
     case code of
  1 :GetErrorStr:='Invalid function number';
  2 :GetErrorStr:='File not found';
  3 :GetErrorStr:='Path not found';
  4 :GetErrorStr:='Too many open files';
  5 :GetErrorStr:='File access denied';
  6 :GetErrorStr:='Invalid file handle';
 12 :GetErrorStr:='Invalid file access code';
 15 :GetErrorStr:='Invalid drive number';
 16 :GetErrorStr:='Cannot remove current directory';
 17 :GetErrorStr:='Cannot rename across drives';
 18 :GetErrorStr:='No more files';
100 :GetErrorStr:='Disk read error';
101 :GetErrorStr:='Disk write error';
102 :GetErrorStr:='File not assigned';
103 :GetErrorStr:='File not open';
104 :GetErrorStr:='File not open for input';
105 :GetErrorStr:='File not open for output';
106 :GetErrorStr:='Invalid numeric format';
150 :GetErrorStr:='Disk is write-protected';
151 :GetErrorStr:='Bad drive request struct length';
152 :GetErrorStr:='Drive not ready';
154 :GetErrorStr:='CRC error in data';
156 :GetErrorStr:='Disk seek error';
157 :GetErrorStr:='Unknown media type';
158 :GetErrorStr:='Sector Not Found';
159 :GetErrorStr:='Printer out of paper';
160 :GetErrorStr:='Device write fault';
161 :GetErrorStr:='Device read fault';
162 :GetErrorStr:='Hardware failure';
200 :GetErrorStr:='Division by zero';
201 :GetErrorStr:='Range check error';
202 :GetErrorStr:='Stack overflow error';
203 :GetErrorStr:='Heap overflow error';
204 :GetErrorStr:='Invalid pointer operation';
205 :GetErrorStr:='Floating point overflow';
206 :GetErrorStr:='Floating point underflow';
207 :GetErrorStr:='Invalid floating point operation';
208 :GetErrorStr:='Overlay manager not installed';
209 :GetErrorStr:='Overlay file read error';
210 :GetErrorStr:='Object not initialized';
211 :GetErrorStr:='Call to abstract method';
212 :GetErrorStr:='Stream registration error';
213 :GetErrorStr:='Collection index out of range';
214 :GetErrorStr:='Collection overflow error';
215 :GetErrorStr:='Arithmetic overflow error';
216 :GetErrorStr:='General Protection fault';
else GetErrorStr:='Unknown error'
end;
end;

begin
end.