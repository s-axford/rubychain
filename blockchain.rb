require 'digest'
require 'uri'
require 'net/http'

class Blockchain
  @chain
  @current_transactions
  @nodes

  def initialize
    @chain = Array.new
    @current_transaction = Array.new
    @nodes = Set.new
    self.new_block(1,100)
  end

  """
  Create a new Block in the Blockchain
  :param proof: <int> The proof given by the Proof of Work algorithm
  :param previous_hash: (Optional) <str> Hash of previous Block
  :return: <dict> New Block
  """
  def new_block(previous_hash=nil , proof)
    block = {
        :index => @chain.length + 1,
        :timestamp => Time.now.strftime("%d/%m/%Y %H:%M"),
        :transactions => @current_transactions,
        :proof => proof,
        :previous_hash => previous_hash || Blockchain.hash(@chain[-1]),
    }

    @current_transactions = []
    @chain.push(block)
    block
  end

  """
  Creates a new transaction to go into the next mined Block
  :param sender: <str> Address of the Sender
  :param recipient: <str> Address of the Recipient
  :param amount: <int> Amount
  :return: <int> The index of the Block that will hold this transaction
  """
  def new_transaction(sender, recipient, amount)
    @current_transactions << {
        :sender => sender,
        :recipient => recipient,
        :amount => amount,
    }
    self.last_block[:index] + 1
  end

  def last_block
    @chain[-1]
  end

  """
  Creates a SHA-256 hash of a Block
  :param block: <dict> Block
  :return: <str>
  """
  def self.hash(block)
    block_string = block.sort_by { |key| key }.to_h.to_s
    Digest::SHA2.new(256).hexdigest block_string
  end


  """
  Simple Proof of Work Algorithm:
  - Find a number p' such that hash(pp') contains leading 4 zeroes, where p is the previous p'
  - p is the previous proof, and p' is the new proof
  :param last_proof: <int>
  :return: <int>
  """
  def proof_of_work(last_proof)
    proof = 0
    until Blockchain.valid_proof(last_proof, proof)
      proof += 1
    end
    proof
  end

  """
  Validates the Proof: Does hash(last_proof, proof) contain 4 leading zeroes?
  :param last_proof: <int> Previous Proof
  :param proof: <int> Current Proof
  :return: <bool> True if correct, False if not.
  """
  def self.valid_proof(last_proof, proof)
    guess = "#{last_proof}#{proof}".encode
    guess_hash = Digest::SHA2.new(256).hexdigest guess
    guess_hash[0..3] == "0000"
  end

  """
  Add a new node to the list of nodes
  :param address: <str> Address of node. Eg. 'http://192.168.0.5:5000'
  :return: None
  """
  def register_node(address)
    parsed_url = URI.parse(address)
    if parsed_url.port
      @nodes.add("#{parsed_url.host}:#{parsed_url.port}")
    else
      @nodes.add(parsed_url.host)
    end
  end

  """
  Determine if a given blockchain is valid
  :param chain: <list> A blockchain
  :return: <bool> True if valid, False if not
  """
  def self.valid_chain(chain)
    last_block = chain[0]
    current_index = 1

    while current_index < chain.length do
      block = chain[current_index]
      puts "#{last_block}"
      puts "#{block}"
      puts "\n-----------\n"
      # Check that the hash of the block is correct
      if block[:previous_hash] != Blockchain.hash(last_block)
        false
      end

      # Check that the Proof of Work is correct
      unless Blockchain.valid_proof(last_block[:proof], block[:proof])
        false
      end

      last_block = block
      current_index += 1
    end
    true
  end

  """
  This is our Consensus Algorithm, it resolves conflicts
  by replacing our chain with the longest one in the network.
  :return: <bool> True if our chain was replaced, False if not
  """
  def resolve_conflicts
    neighbours = @nodes
    new_chain = nil

    # We're only looking for chains longer than ours
    max_length = @chain.length

    # Grab and verify the chains from all the nodes in our network
    neighbours.each {|node|
      node_url = URI.parse("http://#{node}")
      if node_url.port
        response = Net::HTTP.get_response("#{node_url.host}","/chain", node_url.port)
      else
        response = Net::HTTP.get_response("#{node_url.host}","/chain")
      end
      if response.code.to_i == 200
        length = JSON.parse(response.body)["length"]
        chain = JSON.parse(response.body)["chain"]
        # Check if the length is longer and the chain is valid
        if length > max_length and Blockchain.valid_chain(chain)
          max_length = length
          new_chain = chain
        end
      end
    }

      # Replace our chain if we discovered a new, valid chain longer than ours
    if new_chain
      @chain = new_chain
      return true
    end
    false
  end


  attr_reader :chain
  attr_reader :nodes
end
