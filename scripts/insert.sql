USE TestDB
GO
declare @maxid int
select
    @maxid = max(TestID) FROM TESTTABLE

IF @maxid IS NULL
BEGIN
    SET @maxid = 0
END
INSERT INTO TESTTABLE
    SELECT @maxid + 1, 'TEST';
