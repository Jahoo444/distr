/*
	Autor: Jan Tatarynowicz, 204437
*/

import java.util.*;

public class Node extends Thread
{
	private ArrayList< Node > neighbours;
	private Node parent = null;
	private boolean notified = false;
	
	int uid;
	
	public Node( int uid )
	{
		this.uid = uid;
		if( uid == 0 )
			parent = this;
	}
	
	public int getUid() { return this.uid; }
	
	public void setNeighbours( ArrayList< Node > neighbours )
	{
		this.neighbours = neighbours;
	}
	
	public synchronized void send( Node parent )
	{
		if( this.parent == null )
		{
			this.parent = parent;
			for( Node node : this.neighbours )
			{
				if( node != this.parent )
					node.send( this );
			}
			
			System.out.println( uid + " " + parent.getUid() );
		}	
	}
	
	public void run()
	{
		for( Node node : this.neighbours )
		{
			node.send( this );
		}
		/*
		while( true )
		{
		}
		*/
	}
}
