CREATE SOURCE IF NOT EXISTS auction_house
FROM LOAD GENERATOR AUCTION
(TICK INTERVAL '1s', AS OF 100000);

BEGIN;
CREATE TABLE IF NOT EXISTS auctions FROM SOURCE auction_house (REFERENCE auctions);
CREATE TABLE IF NOT EXISTS bids FROM SOURCE auction_house (REFERENCE bids);
COMMIT;

CREATE VIEW IF NOT EXISTS winning_bids AS
SELECT DISTINCT ON (a.id) b.*, a.item, a.seller
FROM auctions AS a
JOIN bids AS b
  ON a.id = b.auction_id
WHERE b.bid_time < a.end_time
  AND mz_now() >= a.end_time
ORDER BY a.id,
  b.amount DESC,
  b.bid_time,
  b.buyer;

CREATE INDEX IF NOT EXISTS wins_by_item ON winning_bids (item);
